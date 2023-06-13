% % % % % This script can be used for plot baselines distribution.
% % % % % Input File: bperp_file
% % % % % Here we plot the absolute perpendicular baseline and Temporal interval

% % % % % Note we do not chose the reference image


clear;
clc;
cmd = ["sed 's/_/ /g' 11ifg_stats.txt | grep -v '*' > 11ifg_stats_new.txt"];
system(cmd);
% % % % % % % % % % % % % %  PARAMETERS NEEDED % % % % % % % % % % % % % % 
pass = 'T072A';
ref=20171117; % first image is chosen as the reference image
fid = fopen('11ifg_stats_new.txt','r');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
data = textscan(fid, '%f%f%f%f%f%f%s', 'CommentStyle','#');
fclose(fid);

data2 = zeros(length(data{1}),5);
data2(:,1) = data{1}; % master YYYYMMDD
data2(:,2) = nan;
data2(:,3) = data{2}; % slave YYYYMMDD
data2(:,4) = nan; 
data2(:,5) = data{3}; % ralative perp. baseline


% msb = [];
for i = 1:size(data2,1)
    if data2(i,1) == ref
        data2(i,2) = 0;
        data2(i,4) = data2(i,5) + data2(i,2);
%         msb = [msb; data2(i,:)];
    end
end

while true
    data3 = data2(~isnan(data2(:,4)),:);
    for i = 1:size(data3,1)
        for j = 1:size(data2,1)
            if data2(j,1) == data3(i,3)
                data2(j,2) = data3(i,4);
                data2(j,4) = data2(j,5) + data2(j,2);
            end
        end
    end
    if sum(isnan(data2(:,2))) == 0
        break;
    end
end

msb = data2(:,1:4);

figure;
hold on;
axis on;
grid on;
ylabel('Perpendicular baseline (m)')
xlabel('Acquisition')


b=[];
for i=1:length(msb)
    a = [msb(i,1) msb(i,2); msb(i,3) msb(i,4)];
    b = [b; a];
end

% remove duplicates
acquisition=unique(b,'rows');
date_1 = num2str(acquisition(:,1));

% plot the nodes
plot(datenum(date_1,'yyyymmdd'), acquisition(:,2),'ko','MarkerFacecolor','r','MarkerSize',6);

% plot the reference node
col = find(acquisition==ref);
ref = num2str(ref);
plot(datenum(ref,'yyyymmdd'), acquisition(col,2),'ko', 'MarkerFacecolor','g','MarkerSize',6);

% conected the nodes
date_2 = num2str(b(:,1));
plot(datenum(date_2,'yyyymmdd'),b(:,2),'Color','k','LineWidth',1)
hold off

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % input the files for GMT ploting % % % % % % % % % % % % % % % % % % 
date = num2str(b(:,1));
yr=date(:,1:4);
mm=date(:,5:6);
dd=date(:,7:8);
date_new = strcat(yr,'-',mm,'-',dd,'T');
filename = strcat('GMT_',pass,'.txt');
fid = fopen(filename,'w');
value = num2str(b(:,2));
for i=1:size(date_new,1)
    fprintf(fid, '%s %s\n', date_new(i,:), value(i,:));
end
fclose(fid)
