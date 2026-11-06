img=hl_cand;

img_proc = abs(filter2(fspecial('sobel')', img));

op = fspecial('average', [4 9]);
img_proc = filter2(op, img_proc);
img_proc(:,c_hl+cen_hl-14:c_hl+cen_hl+14)=0;


se = ones([1 4]);
img_proc = imclose(img_proc, se);

se = ones([5 1]);
img_proc = imopen(img_proc, se);

se = ones([20 1]);
img_with_high_saliences = imopen(img_proc, se);
img_proc = img_proc - img_with_high_saliences;


se = ones([1 5]);
img_proc = imclose(img_proc, se);

se = ones([4 1]);
img_proc = imclose(img_proc, se);

se = ones([1 7]);
img_proc = imopen(img_proc, se);

se = ones([6 1]);
img_proc = imclose(img_proc, se);

img_proc = img_proc >= graythresh(img_proc); % Otsu

se = ones([uint8(5) 1]);
img_proc = imopen(img_proc, se);

se = ones([1 uint8(5) ]);
img_proc = imdilate(img_proc, se);
disp3=img_proc;
[l,num] = bwlabel(img_proc, 4);


for i=1:num
    temp=size(find(l==i),1);
    if temp<250
        l(l==i)=0;
    end
end
img_proc=l;

[l,num] = bwlabel(img_proc, 4);
if num<2
    hl_e=0;
    return
end

pairs=nchoosek(1:num,2);
s = regionprops(img_proc,'centroid');
centroids = cat(1,s.Centroid);
values=centroids;
values(isnan(values(:,1)),:) = [];

for i=1:num
    [r,c]=find(l==i);
    min_r(i)=min(r);
    max_r(i)=max(r);
    min_c(i)=min(c);
    max_c(i)=max(c);
    cen_r(i)=(max(r)+min(r))/2;
    d(i)=cen_r(i)-min_r(i);
    A(i)=length(r);
    AR(i)=(max_r(i)-min_r(i))/(max_c(i)-min_c(i));
end

for i=1:size(pairs,1)
    DS(i)=(1-(abs( d( pairs(i,1) ) - d( pairs(i,2) ) ) )/( d( pairs(i,1) ) + d( pairs(i,2) )))*100;
    AS(i)=(1-(abs( A( pairs(i,1) ) - A( pairs(i,2) ) ) )/( A( pairs(i,1) ) + A( pairs(i,2) )))*100;
    ARS(i)=(1-(abs( AR( pairs(i,1) ) - AR( pairs(i,2) ) ) )/( AR( pairs(i,1) ) + AR( pairs(i,2) )))*100;
    PAR(i)=abs(max_c(pairs(i,1))-max_c(pairs(i,2)))/20;
end
k=[];
for i=1:size(pairs,1)
    if PAR(i)<3 || PAR(i)>8
        DS(i)=0;
        AS(i)=0;
        ARS(i)=0;
        PAR(i)=0;
    end
end

SS=0.8*DS+0.1*AS+0.1*ARS;
[~,b]=max(SS);
a=pairs(b,:);
hl_e=zeros(size(l));
fin_img=zeros(size(l));
r=find(l==a(1));
hl_e(r)=1;
r=find(l==a(2));
hl_e(r)=2;
[r,c]=find(l==a(1));
fin_img(r,c)=1;
[r,c]=find(l==a(2));
fin_img(r,c)=1;

if save_im==1
    imshow(~lp_e.*~fin_img.*orig_img);
end