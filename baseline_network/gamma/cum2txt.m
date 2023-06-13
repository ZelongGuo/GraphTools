clear;clc;

data = h5read('cum_filt.h5','/cum');
mask = h5read('cum_filt.h5','/mask');
corner_lat = h5read('cum_filt.h5','/corner_lat');
corner_lon = h5read('cum_filt.h5','/corner_lon');
post_lat = h5read('cum_filt.h5','/post_lat');
post_lon = h5read('cum_filt.h5','/post_lon');

width  = size(data,1);
nlines = size(data,2);
num = size(data,3);

for ii = 1:width
    for jj = 1:nlines
        lon(jj+(ii-1)*nlines) = corner_lon + (ii-1)*post_lon;
        lat(jj+(ii-1)*nlines) = corner_lat + (jj-1)*post_lat;
    end
end


for i = 1:num
    dataset = data(:,:,i);
    dataset = dataset';
    dataset_v = dataset(:);
    cum_all(:,i)=dataset_v;
end

lon = lon';
lat = lat';

out(:,1) = lon;
out(:,2) = lat;
out(:,3:85)=cum_all;

msk = mask';
msk_v = msk(:);

k = find(msk_v==0);
out(k,3:85) = nan;

save cum_msk.txt -ascii out

