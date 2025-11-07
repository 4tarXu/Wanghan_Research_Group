function y = get_wave(tone, rythm, keynote_change, keynote_type, up_down)
% get_wave：
% tone: 取哪个音节; rythm: 节拍数; keynote_change:升降调8度; keynote_type:当前基调; up_down:音节升降
Fs = 8192; keynote_B = 493; % 开始的节奏降E
keynote_Ab = 415; % 中间变为降A
rythm = 1.25 * rythm;
tones_normal = [1, 3, 5, 6, 8, 10, 12]; % 1-7 到 C D E F G A B映射
if nargin == 5 % 有改变基调&可能有升降调&可能有音节升降
    if keynote_type == 'A'
        keynote = keynote_Ab;
    elseif keynote_type == 'B'
        keynote = keynote_B;
    end
    keynote = keynote * keynote_change;
end
if tone == 0 % 停顿
    tone = 13;
else tone = tones_normal(tone);
end
freqs = [1, 1.059, 1.122, 1.189, 1.260, 1.335, 1.414, 1.498, 1.587, 1.682, 1.782, 1.888, 0] .* keynote.*(1.059^up_down);
x = linspace(0, 2*pi*rythm, floor(Fs*rythm));
y = sin(freqs(tone) * x) .* (1 - x/(2*pi*rythm));
end