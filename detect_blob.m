function [ output_args ] = detect_blob(img_path, thresh, using_downsampling)

%img_path = '../data/butterfly.jpg'; %0.05
%img_path = '../data/sunflowers.jpg'; %0.04
%img_path = '../data/einstein.jpg';
%img_path = '../data/fishes.jpg'; %0.03
%img_path = '../data/bokeh10.jpg';

tic;
num =10;
img = imread(img_path);
% convert it to grayscale and double
im_gray = rgb2gray(img);
im_gray = im2double(im_gray);

if thresh < 0
    thresh = 0.03;
end

[scale_space, mx_scale_space] = get_scale_space(im_gray, using_downsampling);

 % compare with 5X5 neighbours in 2D and 5 layers in 3D
for i=1:num
    indexX = max(1,i-2);
    indexY = min(i+2,num);
    % getting max values around the scale space ie in 3rd dimension
    mx_scale_space(:,:,i) = max(mx_scale_space(:,:,indexX:indexY),[], 3);
end

% getting the centers of circles
for i=1:num
    mx_scale_space(:,:,i) = mx_scale_space(:,:,i) .* (mx_scale_space(:,:,i) == scale_space(:,:,i) & scale_space(:,:,i) > thresh);
end

% Y - rows, Z - columns, R - radius
Y = [];
Z = [];
R = [];
if using_downsampling == 0
    k = 2;
else
    k = 4/3;
end
for i=1:num
    [y,z] = find(mx_scale_space(:,:,i));
    Y = cat(1,Y,y);
    Z = cat(1,Z,z);
    % radius = sigma * 1.41
    if using_downsampling
        sigma = k^(i-1);
    else
        sigma = k^(i-2);
    end
    rad = max(k, sigma * sqrt(2));
    %rad = i * 2;
    rad = repmat(rad, size(y,1), 1);
    R = cat(1, R, rad);
end

show_all_circles(im_gray, Z, Y, R);

toc;
end

function [scale_space, mx_scale_space] = get_scale_space(im_gray, using_downsampling)
    
    if using_downsampling == 0
        % generating filters with different scales
        idx = 0;
        logScales = [0.5,1,2,4,8,16,32,64,128,256];
        num = size(logScales,2);

        for scale = logScales
            idx = idx + 1;
            % normalized filters
            filterBank{idx} = (scale^2) * fspecial('log', 2*ceil(scale*2.5)+1, scale);
        end

        scale_space = zeros(size(im_gray,1), size(im_gray,2), num);

        for i=1:num
            sz = min(5, size(filterBank{i},1));
            filter_response = imfilter(im_gray, filterBank{i}, 'same');
            filter_response = filter_response .^ 2;
            scale_space(:,:,i) = filter_response;
            mx = ordfilt2(filter_response,sz^2,ones(sz));
            mx_scale_space(:,:,i) = mx;
        end
    else
        num = 10;
        loop_img = im_gray;
        scale = 1;
        c_scale_space = cell(num,1);
        filter = fspecial('log', 2*ceil(scale*2.5)+1, scale);
        mx_scale_space = zeros(size(im_gray,1), size(im_gray,2) ,num);

        for i=1:num
            sz = ceil(size(filter,1));

            filter_response = conv2(loop_img, filter, 'same');
            filter_response = filter_response .^ 2;
            c_scale_space{i} = filter_response;

            scale_space(:,:,i) = imresize(filter_response, size(im_gray), 'bicubic');
            mx = ordfilt2(scale_space(:,:,i),sz^2,ones(sz));

            mx_scale_space(:,:,i) = mx;
            loop_img = imresize(loop_img, 0.75, 'bicubic');
        end
    end
end