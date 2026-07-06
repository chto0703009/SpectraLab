function d = compare(a, b)
%COMPARE  Compare two spectra and plot delta.

d = a.compareTo(b);

plot(d.wavelength_nm, d.delta);
grid on;
xlabel("Wavelength (nm)");
ylabel("Delta power");
title("Difference: " + d.label_b + " - " + d.label_a, "Interpreter", "none");

end
