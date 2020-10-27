function out = fun_g(Coeff, Input)

out = Coeff(1) * exp(-(Input-Coeff(3)).^2/(2*Coeff(2).^2));

end 