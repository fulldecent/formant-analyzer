function t1 = normalize(t1);

t1 = (t1 - mean(t1)) / max(abs((t1 - mean(t1))));

