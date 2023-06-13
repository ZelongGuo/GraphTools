% this script is used for deramping and removing the dem-linear componeonts
% from the insar time series. This script is used before the Step 16 [Filter (& Deramp) Time Series] of the
% LICSBAS programs. Then you can used the Step 16 of the LICSBAS to do the
% spatio-temporal filtering.
clear
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if ~exist('cum_deramp_dem.h5','file')
    cmd = ['cp ./TS_GEOCml3GACOS/cum.h5 ./cum_deramp_dem.h5'];
    [status] = system(cmd);
end
datapath = './cum_deramp_dem.h5';
% mask = [125, 250; 160, 327;];
mask = [400, 800; 650, 1050;];
plot_unw = 1;
plot_mask = 1;
plot_dem = 0;
plot_dem_interp = 0;
plot_unw_flat = 1;
plot_deramp = 1;
plot_aps = 1;
% h5disp(datapath)
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%-------------------------------------------
% read the components form the h5 file
%-------------------------------------------
cum = h5read(datapath,'/cum');
imdates = h5read(datapath, '/imdates');
corner_lat = h5read(datapath, '/corner_lat');
corner_lon = h5read(datapath, '/corner_lon');
dem = h5read(datapath, '/hgt');
dem = dem';

if plot_dem == 1
    figure;
    imagesc(dem);
    title("DEM");
    colorbar;
end

% in case nan values of DEM, we'd better to interpolate it
for i = 1:size(dem,1)
    index = 1:length(dem(i,:));
    x = index(~isnan(dem(i,:)));
    v = dem(i,~isnan(dem(i,:)));
    dem(i,:) = interp1(x, v, index);
end
if plot_dem_interp == 1
    figure;
    imagesc(dem);
    title("DEM_interp");
    colorbar;
end

cum_flat = cum * 0 + 1;
for i = 1:size(cum_flat,3)
    %NOTE here is a transposed matrix
    unw = cum(:,:,i)';
    [unw_flat,unw_mask, aps, ramp, params] = deramp_dem_new(unw, mask, dem, 1);
    cum_flat(:,:,i) = unw_flat';
    fprintf('%d / %d images have been done...\n', i, size(cum_flat,3));
end
maxlos = max(unw_flat(:));
minlos = min(unw_flat(:));

% for plotting unw_end and dem
if plot_unw == 1
    figure;
    imagesc(unw);
    title("The original image")
    c = colorbar;
    caxis([minlos, maxlos]);
end

if plot_mask == 1
    figure;
    imagesc(unw_mask);
    title("The masked image")
    caxis([minlos, maxlos]);
end



if plot_unw_flat == 1
    figure;
    imagesc(unw_flat);
    title("The Flattened image");
    colorbar;
    caxis([minlos, maxlos]);
end

if plot_deramp
    figure;
    imagesc(ramp);
    title("Orbit ramp");
    colorbar;
end

if plot_aps
    figure;
    imagesc(aps);
    title("dem-ralated noises");
    colorbar;
end

%**************************************************************************
ts1 = [];
ts2 = [];
for i = 1:size(cum_flat,3)
    unw_ts = cum_flat(:,:,i)';
    temp = unw_ts(200,250);
    ts1 = [ts1; temp];

    unw_ts = cum(:,:,i)';
    temp = unw_ts(200,250);
    ts2 = [ts2; temp];

end
figure;
hold on;
% plot(ts1,'ro')
plot(ts2,'b+')
hold off

% % % -------------------------------------
% NOTE the matlab 2022a,2021b version has bugs of h5write
h5write('cum_deramp_dem.h5','/cum', cum_flat);
% mydata = rand(10,20);
% h5create('test.h5','/cum',[10 20]);
% h5write('test.h5','/cum', mydata);
% cuminfo = h5info('cum_deramp_dem.h5')
% testinfo = h5info('./test.h5')




%-------------------------------------------
% if plot_flag == 1
%     xx = xx';
%     xx = xx(:);
%     yy = yy';
%     yy = yy(:);
%     
%     unw = unw(:);
%     dem = dem(:);
%     unw_mask = unw_mask(:);
% 
%     figure;
%     scatter(xx,yy,[],unw,"filled");
%     colorbar;
%     figure;
%     scatter(xx,yy,[],dem,"filled");
%     colorbar;
%     
%     figure;
%     scatter(xx,yy,[],unw_mask,"filled");
%     % imagesc(unw_mask);
%     colorbar;
% end
