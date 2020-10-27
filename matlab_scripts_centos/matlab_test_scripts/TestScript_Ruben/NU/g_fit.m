function [coeff, g] = g_fit(coeff_use, xref, yval, plot_fit)


coeff = lsqcurvefit(@fun_g, coeff_use, xref, yval, [0 0 -inf]);


end