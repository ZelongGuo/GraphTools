function [unw_flat,unw_mask, aps, ramp, params] = deramp_dem_new(unw, mask, dem, deramp_method)
% this script is used for remove the orbit ramp and dem-linear components
% from the unwrapped interferograms.
% input:
%       unw: the grid of unw file after unwrapping
%       mask: the 2x2 matrix defining the masked area, e.g, mask = ([52, 100; 36, 400])
%       dem: the dem grid used for removing the dem-related components
%       deramp_method:
%               1: a + bx + cy + d*dem
%               2: a + bx + cy + dxy + e*dem
%               3: a + bx + cy + dxy + ex^2 + fy^2 + g*dem (default)
% output:
%       unw_flat: same with ingrid but flattened
%       unw_mask
%       aps: residual dem-ralated noises
%       ramp: the orbit ramp error
%       params
%
% Zelong Guo, 2022.08.10, GFZ, Potsdam

unw_mask = unw;
unw_mask(mask(1,1):mask(1,2), mask(2,1):mask(2,2)) = nan;

x = size(unw,2); %ncols
y = size(unw,1); %nlines
% [xx, yy] = meshgrid(1:x, fliplr(1:y));
[xx, yy] = meshgrid(1:x, 1:y);

xx_mask = xx;
yy_mask = yy;
dem_mask = dem;
xx_mask(isnan(unw_mask)) = nan;
yy_mask(isnan(unw_mask)) = nan;
dem_mask(isnan(unw_mask)) = nan;


% unw_mask2 = unw_mask;
% unw_mask2(isnan(unw_mask)) = 0;
% unw_mask2 = nonzeros(reshape(unw_mask2, x*y, 1));
unw_mask2 = reshape(unw_mask, x*y,1);
unw_mask2(isnan(unw_mask2)) = [];
xx_mask2 = reshape(xx_mask, x*y,1);
xx_mask2(isnan(xx_mask2)) = [];
yy_mask2 = reshape(yy_mask, x*y,1);
yy_mask2(isnan(yy_mask2)) = [];
dem_mask2 = reshape(dem_mask, x*y, 1);
dem_mask2(isnan(dem_mask2)) = [];

if deramp_method == 1
    A = [ones(length(xx_mask2),1) xx_mask2 yy_mask2 dem_mask2];
elseif deramp_method == 2
    A = [ones(length(xx_mask2),1) xx_mask2 yy_mask2 xx_mask2.*yy_mask2 dem_mask2];
else
    A = [ones(length(xx_mask2),1) xx_mask2 yy_mask2 xx_mask2.*yy_mask2  xx_mask2.^2 yy_mask2.^2 dem_mask2];
end


while (1)
    params = A \ unw_mask2; %least squares solution
    v=A*params - unw_mask2;
%     sigma=sqrt((v'*v)/(length(unw_mask2)-7));
    sigma=sqrt((v'*v)/(length(unw_mask2)));
    index=find(abs(v)>3*sigma);
    if isempty(index)
        break;
    end
    A(index,:)=[];
    unw_mask2(index)=[];
end

if deramp_method == 1
    unw_flat = unw - params(1)*ones(y, x) - params(2)*xx - params(3)*yy - params(4).*dem;
    aps = params(4).*dem;
    ramp = params(1)*ones(y, x) + params(2)*xx + params(3)*yy;
elseif deramp_method == 2
    unw_flat = unw - params(1)*ones(y, x) - params(2)*xx - params(3)*yy - params(4).*xx.*yy - params(5).*dem;
    aps = params(5).*dem;
    ramp = params(1)*ones(y, x) + params(2)*xx + params(3)*yy + params(4).*xx.*yy; 
else
    unw_flat = unw - params(1)*ones(y, x) - params(2)*xx - params(3)*yy - params(4).*xx.*yy - params(5).*xx.^2 - params(6).*yy.^2 - params(7).*dem;
    aps = params(7).*dem;
    ramp = params(1)*ones(y, x) + params(2)*xx + params(3)*yy + params(4).*xx.*yy + params(5).*xx.^2 + params(6).*yy.^2;
end
unw_flat(isnan(unw))=nan;
aps(isnan(unw))=nan;
ramp(isnan(unw)) = nan;

end