function dx = three_tank_model_faulty(t, x, u, params)
    % Parametry geometryczne
    al = params.al;
    am = params.am;
    ar = params.ar;
    ab = params.ab;
    vol = params.vol;

    % Parametry przepływu (stałe)
    klb = params.klb;
    klm = params.klm;
    krb = params.krb;
    kmr = params.kmr;

    kl = params.kl;
    kr = params.kr;
    
    % 1. Sekcja: Awaria Zaworów
    % Awaria zaworu prawego po 80 s
    % if t > 80
    %     krb = 0; % Zawór prawy przestaje działać
    % end
    % % Awaria zaworu lewego po 100 s
    % if t > 100
    %     klb = 0; % Zawór lewy przestaje działać
    % end
    % % Awaria zaworu między zbiornikami lewym a środkowym po 120 s
    % if t > 120
    %     klm = 0; % Zawór między lewym a środkowym przestaje działać
    % end
    % % Awaria zaworu między zbiornikami środkowym a prawym po 150 s
    % if t > 150
    %     kmr = 0; % Zawór między środkowym a prawym przestaje działać
    % end
    % 
    % % 2. Sekcja: Awaria Pomp
    % % Awaria prawej pompy po 50 sekundach (zmniejszenie wydajności)
    % if t > 50
    %     kr = params.kr * 0.2;  % Awaria prawej pompy (wydajność zmniejsza się do 20%)
    % end
    % % Awaria lewej pompy po 60 sekundach (zmniejszenie wydajności)
    % if t > 60
    %     kl = params.kl * 0.5;  % Awaria lewej pompy (wydajność zmniejsza się do 50%)
    % end
    % % Awaria obu pomp po 90 sekundach
    % if t > 90
    %     kl = params.kl * 0.3;  % Awaria lewej pompy (wydajność zmniejsza się do 30%)
    %     kr = params.kr * 0.1;  % Awaria prawej pompy (wydajność zmniejsza się do 10%)
    % end
    % % Awaria obu pomp (brak przepływu) po 120 sekundach
    if t > 120
        kl = 0;  % Brak przepływu przez lewą pompę
        kr = 0;  % Brak przepływu przez prawą pompę
    end

    % % 3. Sekcja: Awaria Zamulenia Zbiornika
    % % Zamulenie zbiornika lewego po 60 sekundach
    % if t > 60
    %     al = params.al * 0.6;  % Zmniejszenie powierzchni zbiornika lewego o 20%
    % end
    % % Zamulenie zbiornika środkowego po 90 sekundach
    % if t > 90
    %     am = params.am * 0.75;  % Zmniejszenie powierzchni zbiornika środkowego o 25%
    % end
    % % Zamulenie zbiornika prawego po 120 sekundach
    % if t > 120
    %     ar = params.ar * 0.7;  % Zmniejszenie powierzchni zbiornika prawego o 30%
    % end
    
    % Stany
    hl = x(1);
    hm = x(2);
    hr = x(3);
    
    % Poziom w zbiorniku dolnym
    hb = (vol - al*hl - am*hm - ar*hr) / ab;

    % Nieliniowa funkcja przepływu
    s = @(x) sign(x) * sqrt(abs(x));

    % Równania przepływu
    dhl = (1/al)*(-klb*s(hl - hb) - klm*s(hl - hm) + kl*u(1));
    dhm = (1/am)*(klm*s(hl - hm) - kmr*s(hm - hr));
    dhr = (1/ar)*(kmr*s(hm - hr) - krb*s(hr - hb) + kr*u(2));
    dhb = (1/ab)*(klb*s(hl-hb) + krb*s(hr-hb));

    dx = [dhl; dhm; dhr];
end