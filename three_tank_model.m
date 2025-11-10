function dx = three_tank_model(t, x, u, params)
    % x = [hl; hm; hr];   poziomy cieczy w lewym, środkowym i prawym zbiorniku
    % u = [ul; ur];       napięcia sterujące pompami

    % Parametry
    al = params.al;
    am = params.am;
    ar = params.ar;
    ab = params.ab;
    
    klb = params.klb;
    klm = params.klm;
    kmr = params.kmr;
    krb = params.krb;
    kl  = params.kl;
    kr  = params.kr;
    vol = params.vol;

    hl = x(1);
    hm = x(2);
    hr = x(3);

    % Oblicz poziom cieczy w zbiorniku dolnym z zasady zachowania objętości
    hb = (vol - al*hl - am*hm - ar*hr) / ab;

    % Pomocnicza funkcja przepływu: s(x) = sign(x) * sqrt(abs(x))
    s = @(x) sign(x) * sqrt(abs(x));

    % Równania różniczkowe
    dhl = (1/al)*(-klb*s(hl - hb) - klm*s(hl - hm) + kl*u(1));
    dhm = (1/am)*(klm*s(hl - hm) - kmr*s(hm - hr));
    dhr = (1/ar)*(kmr*s(hm - hr) - krb*s(hr - hb) + kr*u(2));

    dx = [dhl; dhm; dhr];
end
