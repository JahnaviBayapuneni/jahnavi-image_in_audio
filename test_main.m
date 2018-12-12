clc;
clear all;
warning off;
format long;

% Set each variable to 1 if you want to apply the corresponding signal
% processing operation (such as filtering, resampling, compression, ...)
ok_resamplig      = 1;  % if 1 sound is resampled
ok_noise          = 1;  % if 1 sound is added with rand noise
ok_filtering      = 1;  % if 1 sound is low-pass filtered
ok_requantization = 1;  % if 1 sound is requantized
ok_mp3            = 1;  % if 1 sound is converted into mp3
ok_cropping       = 0;  % if 1 sound is cropped

[x,Fs] = audioread('LoopyMusic.wav');
plot(Fs,x);
% Stereo to mono conversion
if size(x,1)==2
    x = (x(1,:) + x(2,:))/2;
end
if size(x,2)==2
    x = (x(:,1) + x(:,2))/2;
end
L = length(x);
% Watermarking parameter
alpha = 0.05;
% Watermarking signal
Pmin      = 10;
w         = randn(L,1);
w(1:Pmin) = 0;

disp('Please wait... watermark insertion.');
disp(' ');

% Watermarked signal
% function [y] = w_embedding(x,w,alpha)
% Audio watermark embedding.
% INPUTS
% x:     input sound
% w:     watermarking signal
% alpha: watermaking parameter (a big value generates a stronger watermark)
% OUTPUTS
% y:     watermarked sound
[y] = w_embedding(x,w,alpha);
% Signal to noise ratio of original input sound after watermark insertion
SNR = 10*log10(sum(x.^2)/sum((x-y).^2));
disp('SNR of original input sound after watermark insertion');
disp(SNR);

% sound(y,Fs);
% pause;
%--------------------------------------------------------------------------
signal = y;
% Signal manipulation

if ok_resamplig
    % Resampling
    Fs_0 = Fs;
    Fs_1 = round(Fs/9);
    signal = resample(signal,Fs_1,Fs_0);
    signal = resample(signal,Fs_0,Fs_1);
    if length(signal)<L
        signal(end+L) = 0;
    end
    if length(signal)>L
        signal = signal(1:L);
    end
end

if ok_noise
    % Additional noise
    signal = signal+0.1*rand(size(signal));
end

if ok_filtering
    % Filtering
    myfilter = ones(20,1);
    myfilter = myfilter/sum(myfilter);
    signal   = filter(myfilter,1,signal);
end

if ok_requantization
    % Requantization
    bits_new = 8;
    wavwrite(signal,Fs,bits_new,'requantized_sound.wav');
    [signal] = wavread('requantized_sound.wav');
end

if ok_mp3
    % Mp3 conversion
    %
    % References: 
    % Alfredo Fernandez
    % MP3WRITE and MP3READ  
    % Code downloaded at
    % http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=6152&objectType=FILE
    %
    
    audiowrite(signal,Fs,'sound.wav');
    [signal,Fs_mp3] = audioread('sound.wav');
    if length(signal)<L
        signal(end+L) = 0;
    end
    if length(signal)>L
        signal = signal(1:L);
    end
end

if ok_cropping
    % Cropping
    Lmin = round(L/11);
    Lmax = round(5*L/11);
    signal(1:Lmin)   = 0;
    signal(Lmax:end) = 0;    
end

% Signal to noise ratio after corruption (noise, mp3 compression, filtering, ...)
SNR = 10*log10(sum(x.^2)/sum((x-signal).^2));
disp('SNR of watermarked, corrupted sound');
disp(SNR);

disp('Please wait... watermark detection.');
disp(' ');

% function [detected_watermarking] = w_detection(signal,w,alpha)
% Audio watermark detection.
% INPUTS
% signal:     watermarked (and eventually corrupted) sound
% w:          watermarking signal
% alpha:      watermaking parameter (a big value generates a stronger watermark)
% x:          unwatermarked sound
% OUTPUTS
% detected:   1 if watermark is detected, 0 if watermark is not
%             detected
[detected] = w_detection(signal,w,alpha);
if detected
    disp('Watermark has been detected');
else
    disp('Watermark has NOT been detected');
end
%--------------------------------------------------------------------------
%%
% % If you want to try to detect another watermarking signal just uncomment
% % the following lines. 
% &
% % Another watermarking signal (it should NOT been revealed)
w2         = randn(L,1);
w2(1:Pmin) = 0;
[detected] = w_detection(signal,w2,alpha);
if detected
    disp('Watermarked sound');
else
    disp('Non-watermarked sound');
end
%--------------------------------------------------------------------------

