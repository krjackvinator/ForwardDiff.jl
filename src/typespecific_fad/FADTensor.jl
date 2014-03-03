immutable FADTensor{T<:Real, n} <: Number
  h::FADHessian{T, n} 
  t::Vector{T}
end

FADTensor{T<:Real, n} (h::FADHessian{T, n}, t::Vector{T}) = FADTensor{T, length(h.d.g)}(h, t)

FADTensor{T<:Real, n} (h::FADHessian{T, n}) = FADTensor{T, length(h.d.g)}(h, zeros(T, n^3))

function FADTensor{T<:Real}(v::Vector{T})
  n = length(v)
  Tensor = Array(FADTensor{T, n}, n)
  for i=1:n
    g = zeros(T, n)
    g[i] = one(T)
    Tensor[i] = FADTensor(FADHessian(GraDual{T, n}(v[i], g), zeros(T, convert(Int, n*(n+1)/2))), zeros(T, n^3))
  end
  return Tensor
end

zero{T, n}(::Type{FADTensor{T, n}}) = FADTensor(zero(FADHessian{T, n}), zeros(T, n^3))
one{T, n}(::Type{FADTensor{T, n}}) = FADTensor(one(FADHessian{T, n}), zeros(T, n^3))

value(x::FADTensor) = value(x.h)
value{T<:Real, n}(X::Vector{FADTensor{T, n}}) = [x.h.d.v for x in X]

grad(x::FADTensor) = grad(x.h)
function grad{T<:Real, n}(X::Vector{FADTensor{T, n}})
  m = length(X)
  reshape([x.h.d.g[i] for x in X, i in 1:n], m, n)
end

hessian{T<:Real, n}(x::FADTensor{T, n}) = hessian(x.h)

function tensor{T<:Real, n}(x::FADTensor{T, n})
  y = Array(T, n, n, n)
  k = 1
  
  for a in 1:n
    for i in 1:n
      for j in 1:i
        y[a, i, j] = x.t[k]
        k += 1
      end
    end

    for i in 1:n
      for j in (i+1):n
        y[a, i, j] = y[a, j, i]
      end
    end
  end

  y
end

convert{T<:Real, n}(::Type{FADTensor{T, n}}, x::FADTensor{T, n}) = x
convert{T<:Real, n}(::Type{FADTensor{T, n}}, x::T) =
  FADTensor(FADHessian{T, n}(x, zeros(T, convert(Int, n*(n+1)/2))), zeros(T, n^3))
convert{T<:Real, S<:Real, n}(::Type{FADTensor{T, n}}, x::S) = 
  FADTensor(FADHessian{T, n}(convert(T, x), zeros(T, convert(Int, n*(n+1)/2))), zeros(T, n^3))
convert{T<:Real, S<:Real, n}(::Type{FADTensor{T, n}}, x::FADTensor{S, n}) =
  FADTensor(FADHessian{T, n}(GraDual{T, n}(convert(T, x.h.d.v), convert(Vector{T}, x.h.d.g)),
  convert(Vector{T}, x.h.h)), convert(Vector{T}, x.t))
convert{T<:Real, S<:Real, n}(::Type{T}, x::FADTensor{S, n}) =
  ((x.h.d.g == zeros(S, n) && x.h.h == zeros(S, convert(Int, n*(n+1)/2)) && x.h.t == zeros(S, n^3)) ? 
  convert(T, x.h.d.v) : throw(InexactError()))

promote_rule{T<:Real, n}(::Type{FADTensor{T, n}}, ::Type{T}) = FADTensor{T, n}
promote_rule{T<:Real, S<:Real, n}(::Type{FADTensor{T, n}}, ::Type{S}) = FADTensor{promote_type(T, S), n}
promote_rule{T<:Real, S<:Real, n}(::Type{FADTensor{T, n}}, ::Type{FADTensor{S, n}}) = FADTensor{promote_type(T, S), n}

isfadtensor(x::FADTensor) = true
isfadtensor(x::Number) = false

isconstant{T<:Real, n}(x::FADTensor{T, n}) = (isconstant(x.h) && x.t == zeros(T, n^3))
iszero{T<:Real, n}(x::FADTensor{T, n}) = isconstant(x) && (x.h.d.v == zero(T))
isfinite{T<:Real, n}(x::FADTensor{T, n}) = (isfinite(x.h) && x.t == ones(T, n^3))

=={T<:Real, n}(x1::FADTensor{T, n}, x2::FADTensor{T, n}) = ((x1.h == x2.h) && (x1.t == x2.t))
  
show(io::IO, x::FADTensor) =
  print(io, "FADTensor(\nvalue:\n", value(x),
  "\n\ngrad:\n", grad(x),
  "\n\nHessian:\n", hessian(x),
  "\n\nTensor:\n", tensor(x),
  "\n)")

+{T<:Real, n}(x1::FADTensor{T, n}, x2::FADTensor{T, n}) = FADTensor{T, n}(x1.h+x2.h, x1.t+x2.t)

-{T<:Real, n}(x::FADTensor{T, n}) = FADTensor{T,n}(-x.h, -x.t)
-{T<:Real, n}(x1::FADTensor{T, n}, x2::FADTensor{T, n}) = FADTensor{T, n}(x1.h-x2.h, x1.t-x2.t)
