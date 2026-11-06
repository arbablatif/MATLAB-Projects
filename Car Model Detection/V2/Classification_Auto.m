%%  File to calculate the accuracy of the bulk data. Need only one data and
%       set the percentage for Training and Testing
%
%   1) Extract the features, run the following
%                 FS_train.m
%
%   2) Move Target car to the specific folder

clear all;  close all;  clc;
Target_car='.\Features\Target\';   % Target car feature directory
Other_car='.\Features\';   % Target car feature directory
TC_train=70;      % Percent Sample of the Target car for training
OC_Test=100;       % Percent sample of the other cars for testing

%% Nothing to Change
oc_nu=4;

matset = dir([Target_car,'\*.mat']);
ndata=length(matset);
Fin=[];
fin_test=[];

target_num=[];
for dd=1:ndata
    currentfilename = [matset(dd).folder,'\',matset(dd).name];
    Fil=open(currentfilename);
    Target_name=matset(dd).name(4:end-4);
    Data=cell2mat(Fil.Data2(:,1)')';
    tr_sa=round(TC_train*size(Data,1)/100);
    rand_data=randi(tr_sa,size(Data,1),1);
    tr_data=Data(rand_data,:);
    Name=Fil.Data2(rand_data,2);
    new=str2double(matset(dd).name(1:3))*ones(size(tr_data,1),1);
    target_num=[target_num; str2double(matset(dd).name(1:3))];
    Fin=[Fin; new tr_data];
    rand_data=randi(size(Data,1)-tr_sa,size(Data,1),1);
    te_data=Data(rand_data,:);
    new=str2double(matset(dd).name(1:3))*ones(size(te_data,1),1);
    Name_test=Fil.Data2(rand_data,2);
    fin_test=[fin_test; new te_data];
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

[r,c]=find(res==target_num');
d=zeros(size(res,1),1);
d(r,1)=1;
res(:,1)=d(:,1);
Test_Bad=any(fin_test(:,2:end),2);
Name_te_bad=Name_test(~Test_Bad,:);
Name_te=Name_test(Test_Bad,:);
Fin_Temp=fin_test(Test_Bad,:);
orig=Fin_Temp(:,1);
test=Fin_Temp(:,2:end);
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
figure(1);
histogram(final)
title('Results with the Target cars')

fin_c=length(find(final==1));
fin_fn=length(find(final==-1));
result_test=[Name_te num2cell(final)];

%% Test Other
Test_data = dir([Other_car,'\*.mat']);
ndata=length(Test_data);
fin_test=[];
Name=[];
for dd=1:ndata
    currentfilename = [Test_data(dd).folder,'\',Test_data(dd).name];
    if length(Test_data(dd).name)<8
        continue   % skip files without a proper name
    else
        Fil=open(currentfilename);
        Data=cell2mat(Fil.Data2(:,1)')';
        temp=randperm(size(Data,1));
        te_sa=round(OC_Test*size(Data,1)/100);
        te_data_o=Data(temp(1:te_sa),:);
        Name=[Name; Fil.Data2(temp(1:te_sa),2)];
        new=str2double(Test_data(dd).name(1:3))*ones(size(te_data_o,1),1);
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
figure(2); histogram(final_1)
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

%% Summary chart (saved for the README)
fig = figure('Color', 'w');
bar(categorical({'Target car', 'Other cars'}), [fin_c fin_fn; fin_ce fin_fp], 'stacked');
legend('Correct', 'Wrong', 'Location', 'northwest')
ylabel('Number of test samples')
title(sprintf('V2 classifier, target car: %s (accuracy %.1f %%)', ...
    strtrim(strrep(Target_name, '_', ' ')), acc))
if exist('theme', 'file') == 2 || exist('theme', 'builtin') == 5
    theme(fig, 'light');
end
if isfolder(fullfile('..', 'figures'))
    exportgraphics(fig, fullfile('..', 'figures', 'v2_results.png'), 'Resolution', 150);
end
