 function c = plus(a, b)
%function c = plus(a, b)
% "plus" method for this class

if isa(a, 'Fatrix')
 a = a * eye(a.dim(2));
end
if isa(b, 'Fatrix')
 b = b * eye(b.dim(2));
end

c = a + b;
