
%% Detection from the LP
[l,num] = bwlabel(lp_e, 4);
[y,x]=find(l==1);
min_y_lp=min(y);
max_y_lp=max(y);
heit_lp=max_y_lp-min_y_lp;
min_x_lp=min(x);
max_x_lp=max(x);
widt_lp=max_x_lp-min_x_lp;
cen_y_lp=(min_y_lp+max_y_lp)/2;
cen_x_lp=(min_x_lp+max_x_lp)/2;

if hl_e==0
    feat=zeros(140,1);
    return
end
%% Detection from the HL

l=hl_e;
[y,x]=find(l==1);
min_y_hl_1=min(y);
max_y_hl_1=max(y);
heit_hl_1=max_y_hl_1-min_y_hl_1;
min_x_hl_1=min(x);
max_x_hl_1=max(x);
widt_hl_1=max_x_hl_1-min_x_hl_1;
cen_y_hl_1=(min_y_hl_1+max_y_hl_1)/2;
cen_x_hl_1=(min_x_hl_1+max_x_hl_1)/2;


[y,x]=find(l==2);
min_y_hl_2=min(y);
max_y_hl_2=max(y);
heit_hl_2=max_y_hl_2-min_y_hl_2;
min_x_hl_2=min(x);
max_x_hl_2=max(x);
widt_hl_2=max_x_hl_2-min_x_hl_2;
cen_y_hl_2=(min_y_hl_2+max_y_hl_2)/2;
cen_x_hl_2=(min_x_hl_2+max_x_hl_2)/2;



%% Features Calculation
AR_TL_1=widt_hl_1/heit_hl_1;    %1
AR_TL_2=widt_hl_2/heit_hl_2;    %2
AR_TL_LP_W_1=widt_hl_1/widt_lp; %3
AR_TL_LP_W_2=widt_hl_2/widt_lp; %5
AR_TL_LP_H_1=heit_hl_1/heit_lp; %4
AR_TL_LP_H_2=heit_hl_2/heit_lp; %6
UV=sqrt((cen_x_lp-cen_x_hl_1)^2+(cen_y_lp-cen_y_hl_1)^2);
UZ=abs(cen_x_hl_1-cen_x_lp);
theta1_ol=acosd((cen_x_lp*cen_x_hl_1+cen_y_lp*cen_y_hl_1)/ ...
    (sqrt(cen_x_lp^2+cen_y_lp^2)*sqrt(cen_x_hl_1^2+cen_y_hl_1^2)))+180; %7
theta1=acosd(UZ/UV); %7
theta2=acosd((cen_x_lp*cen_x_hl_2+cen_y_lp*cen_y_hl_2)/ ...
    (sqrt(cen_x_lp^2+cen_y_lp^2)*sqrt(cen_x_hl_2^2+cen_y_hl_2^2)));     %8
AR_Dist_TL_LP_W=sqrt((cen_x_hl_1-cen_x_hl_2)^2+(cen_y_hl_1-cen_y_hl_2)^2)/widt_lp; %9
AR_Dist_TL_TL_W=sqrt((cen_x_hl_1-cen_x_hl_2)^2+(cen_y_hl_1-cen_y_hl_2)^2)/( (widt_hl_1+widt_hl_2)/2 );  %12
AR_Dist_TL_LP_H_1=sqrt((cen_x_hl_1-cen_x_lp)^2+(cen_y_hl_1-cen_y_lp)^2)/heit_lp; %10
AR_Dist_TL_LP_H_2=sqrt((cen_x_hl_2-cen_x_lp)^2+(cen_y_hl_2-cen_y_lp)^2)/heit_lp; %11

[mask_r,mask_c]=find(l==1);
hl_1=orig_img(min(mask_r):max(mask_r),min(mask_c):max(mask_c));
hl_1 = hl_1 >= graythresh(hl_1); % Otsu
fe_hl_1=imresize(hl_1,[8 8]);


[mask_r,mask_c]=find(l==2);
hl_2=orig_img(min(mask_r):max(mask_r),min(mask_c):max(mask_c));
hl_2 = hl_2 >= graythresh(hl_2); % Otsu
fe_hl_2=imresize(hl_2,[8 8]);

feat=[ AR_TL_1; 
AR_TL_2;
AR_TL_LP_W_1;
AR_TL_LP_H_1;
AR_TL_LP_W_2;
AR_TL_LP_H_2;
theta1;
theta2;
AR_Dist_TL_LP_W;
AR_Dist_TL_LP_H_1;
AR_Dist_TL_LP_H_2;
AR_Dist_TL_TL_W;
reshape(fe_hl_1,[],1);
reshape(fe_hl_2,[],1)];