module Torch

using TorchCAPI_jll

export Tensor, tensor, Scalar

using ZygoteRules
using ZygoteRules: @adjoint
using NNlib
using NNlib: PoolDims
using Requires
using FillArrays

TURN_ON_LOGGING = false

include("wrapper.jl")

using .Wrapper

# sync + clear empty cache
const clear_cache = at_empty_cache
const sync = at_sync

include("tensor.jl")
include("scalar.jl")
include("nnlib.jl")
include("ops.jl")
include("normalise.jl")
include("broadcast.jl")
include("statistics.jl")

include("grads.jl")
include("utils.jl")

@init @require Flux="587475ba-b771-5e3f-ad9e-33799f191a9c" begin
  using .Flux

  function (tbn::Flux.BatchNorm)(x::Tensor)
    tbn.λ.(Torch.batchnorm(x, tbn.γ,  tbn.β,  tbn.μ, tbn.σ², 0, tbn.momentum, tbn.ϵ, 1))
  end

  function Flux.Zygote.accum(t1::Tensor, t2::Tensor{T,N}) where {T,N}
    ptr = Ref(Ptr{Cvoid}())

    Torch.Wrapper.atg_add_(ptr, t1.ptr, t2.ptr)
    Tensor{T,N}(ptr[], Torch.on(t1))
  end

  eval(:(Flux.Zygote.@nograd Torch.Wrapper.at_copy_data))
  eval(:(Flux.Zygote.@nograd Torch.Wrapper.at_dim))
  torch(x) = Flux.fmap(to_tensor, x)
end

end # module
