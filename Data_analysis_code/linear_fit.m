function yCalc = linear_fit(x, y)
X = [ones(length(x),1) x];
b = X\y;
yCalc = [ones(length(x),1) x]*b;
end