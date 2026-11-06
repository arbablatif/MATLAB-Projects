%%  File to calculate the accuracy of the bulk data
%
%   1) Extract the features, run the following
%                 FS_train.m
%                 FS_test.m
%
%   2) Move Target car to the specific folders

clear all; close all; clc;
Target_car='.\Features\Target\';   % Target car feature directory
Other_car='.\Features\';   % Target car feature directory
Test_target='.\Test\Target\';   % Target car test
Test_other='.\Test\';   % Target car test


%% Nothing to Change
oc_nu=4;

matset = dir([Target_car,'\*.mat']);
ndata=length(matset);
Fin=[];
target_num=[];
for dd=1:ndata
    currentfilename = [matset(dd).folder,'\',matset(dd).name];
    Fil=open(currentfilename);
    Target_name=matset(dd).name(4:end-4);
    Data=cell2mat(Fil.Data2(:,1)')';
    Name=Fil.Data2(:,2);
%     Data=Fil.Data';
    new=str2double(matset(dd).name(1:3))*ones(size(Data,1),1);
    target_num=[target_num; str2double(matset(dd).name(1:3))];
    Fin=[Fin; new Data];
end
matset = dir([Other_car,'\*.mat']);
ndata=length(matset);
for dd=1:ndata
    currentfilename = [matset(dd).folder,'\',matset(dd).name];
    if length(matset(dd).name)<8
        continue   % skip files without a proper name
    else
        Fil=open(currentfilename);
            Data_temp=cell2mat(Fil.Data2(:,1)')';
     
         rand_data=randi(size(Data_temp,1),oc_nu,1);
             Name=[Name;Fil.Data2(rand_data,2)];
%         Data_temp=Fil.Data';
        Data=Data_temp(rand_data,:);
        new=str2double(matset(dd).name(1:3))*ones(size(Data,1),1);
        Fin=[Fin; new Data];
    end
end

Bad_F=any(Fin(:,2:end),2);
Name_tr_bad=Name(~Bad_F,:);
Name_tr=Name(Bad_F,:);
Fin_Temp=Fin(Bad_F,:);
res=Fin_Temp(:,1);
pre=Fin_Temp(:,2:end);
% clearvars -except pre res temp


Test_data = dir([Test_target,'\*.mat']);
ndata=length(Test_data);
fin_test=[];
for dd=1:ndata
    currentfilename = [Test_data(dd).folder,'\',Test_data(dd).name];
    if length(Test_data(dd).name)<8
        continue   % skip files without a proper name
    else
        Fil=open(currentfilename);
%         Data=Fil.Data';
   Data=cell2mat(Fil.Data2(:,1)')';
    Name=Fil.Data2(:,2);
        new=str2double(Test_data(dd).name(1:3))*ones(size(Data,1),1);
        fin_test=[fin_test; new Data];
    end
end

Test_Bad=any(fin_test(:,2:end),2);
Name_te_bad=Name(~Test_Bad,:);
Name_te=Name(Test_Bad,:);
Fin_Temp=fin_test(Test_Bad,:);
orig=Fin_Temp(:,1);
test=Fin_Temp(:,2:end);
% clearvars -except pre res test orig temp
% pre=test;
[r,c]=find(res==target_num');
d=zeros(size(res,1),1);
d(r,1)=1;
res(:,1)=d(:,1);
% pre=d(:,2:end);
%% knn Classifier
knn_3_mod=fitcknn(pre,res,'NumNeighbors',3,'Distance','euclidean');
knn_5_mod=fitcknn(pre,res,'NumNeighbors',5,'Distance','euclidean');
knn_7_mod=fitcknn(pre,res,'NumNeighbors',7,'Distance','euclidean');
CVMdl_knn_3 = crossval(knn_3_mod,'KFold',10);
kloss_knn_3 = kfoldLoss(CVMdl_knn_3);
CVMdl_knn_5 = crossval(knn_5_mod,'KFold',10);
kloss_knn_5 = kfoldLoss(CVMdl_knn_5);
CVMdl_knn_7 = crossval(knn_7_mod,'KFold',10);
kloss_knn_7 = kfoldLoss(CVMdl_knn_7);
%% SVM Classifier
svm_mod=fitcsvm(pre,res,'Standardize',true,'KernelFunction','RBF','KernelScale','auto');
CVMdl_svm = crossval(svm_mod,'KFold',10);
kloss_svm = kfoldLoss(CVMdl_svm);
%% DT Classifier
dt_mod=fitctree(pre,res);
CVMdl_dt = crossval(dt_mod,'KFold',10);
kloss_dt = kfoldLoss(CVMdl_dt);


%% Estimation
pr_k_3=predict(knn_3_mod,test);
pr_k_5=predict(knn_5_mod,test);
pr_k_7=predict(knn_7_mod,test);

Knn_comb=pr_k_3+pr_k_5+pr_k_7;
Knn_comb(Knn_comb<2)=0;
Knn_comb(Knn_comb>1)=1;

pr_svm=predict(svm_mod,test);
pr_dt=predict(dt_mod,test);

%% Final Decision
final=1/3*(Knn_comb+ pr_svm +pr_dt);
final(final>0.5)=1;
final(final<0.5)=-1;
histogram(final)
title('Results with the Target cars')
% comb1=[final pr_dt pr_svm Knn_comb orig];

fin_c=length(find(final==1));
fin_fn=length(find(final==-1));
result_test=[Name_te num2cell(final)];


%% Test Other
Test_data = dir([Test_other,'\*.mat']);
ndata=length(Test_data);
fin_test=[];
Name=[];
for dd=1:ndata
    currentfilename = [Test_data(dd).folder,'\',Test_data(dd).name];
    if length(Test_data(dd).name)<8
        continue   % skip files without a proper name
    else
        Fil=open(currentfilename);
%         Data=Fil.Data';
   Data=cell2mat(Fil.Data2(:,1)')';
    Name=[Name; Fil.Data2(:,2)];
        new=str2double(Test_data(dd).name(1:3))*ones(size(Data,1),1);
        fin_test=[fin_test; new Data];
    end
end


Test_Bad_o=any(fin_test(:,2:end),2);
Name_te_o_bad=Name(~Test_Bad_o,:);
Name_te_o=Name(Test_Bad_o,:);
Fin_Temp=fin_test(Test_Bad_o,:);
orig_other=Fin_Temp(:,1);
test_other=Fin_Temp(:,2:end);

pr_k_3=predict(knn_3_mod,test_other);
pr_k_5=predict(knn_5_mod,test_other);
pr_k_7=predict(knn_7_mod,test_other);
Knn_comb=pr_k_3+pr_k_5+pr_k_7;
Knn_comb(Knn_comb<2)=0;
Knn_comb(Knn_comb>1)=1;

pr_svm=predict(svm_mod,test_other);
pr_dt=predict(dt_mod,test_other);


final_1=1/3*(Knn_comb+ pr_svm +pr_dt);
final_1(final_1>0.5)=1;
final_1(final_1<0.5)=-1;
figure; histogram(final_1)
title('Results with the Other cars')

result_test_o=[Name_te_o num2cell(final_1)];
fin_fp=length(find(final_1==1));
fin_ce=length(find(final_1==-1));


%% Result Final
total=fin_c+fin_fn+fin_fp+fin_ce;

err=(fin_fn+fin_fp)/total;
acc=(1-err)*100;

fprintf('The accuracy of the car model: %s is %2.3f%%. \n',Target_name, acc);
fprintf('|--------------------------------------------------------|\n');
fprintf('|  Total Tested  |  False Positive   |   False Negative  |\n');
fprintf('|--------------------------------------------------------|\n');
fprintf('|       %d     |          %d        |         %d        |\n',total, fin_fp, fin_fn);
fprintf('|--------------------------------------------------------|\n');
clearvars -except acc result_test result_test_o