
% Code adapted from https://github.com/gordonberman/MotionMapper
% Modified by Mackenzie Mathis (https://github.com/MMathisLab) 
% ---- use this code to load the trajectories from DeepLabCut 
% to perform clustering as in: 
% "Mapping the stereotyped behaviour of freely-moving fruit flies" 
% by Berman, GJ, Choi, DM, Bialek, W, and Shaevitz, JW, J. Royal Society Interface, 99, 20140672 (2014)

% make sure the whole folder is on the path first 

%add utilities folder to path
if isunix
    addpath(genpath('./utilities/'));
else
    addpath('utilities');
end

%% Set parameters:
% LOAD .CSV FILE from DeepLabCut!!! 
% You can use this below (if less than 11 columns, or edit the helper fxn),
% or simply click on your file and use the Import wizard to grab all the data....

filePath = './';
TaskName ='yourTaskNameHere';
deeplabcutfile = 'HK_20190528_151044_side_dalotia1_DeadliomstumpRight_t1DeepCut_resnet50_ball_dalotiaMay31shuffle1_300000.csv'

%input header information:
%[Dalotia_abdomen_tip_x, Dalotia_abdomen_tip_y, Dalotia_abdomen_tip_h,...
%    Dalotia_abdomen_middle_x, Dalotia_abdomen_middle_y, Dalotia_abdomen_middle_h,...
%    Dalotia_abdomen_base_x, Dalotia_abdomen_base_y, Dalotia_abdomen_base_h,...
%    Dalotia_elytra_x, Dalotia_elytra_y, Dalotia_elytra_h] = importDeepLabCutfile(deeplabcutfile, 4, 1000);
    %Dalotia_pronotum_x, Dalotia_pronotum_y, Dalotia_pronotum_h,...
    %Dalotia_head_x, Dalotia_head_y, Dalotia_head_h,...
    %Dalotia_antenna_right_tip_x, Dalotia_antenna_right_tip_y, Dalotia_antenna_right_tip_h,...
    %Dalotia_antenna_left_tip_x, Dalotia_antenna_left_tip_y, Dalotia_antenna_left_tip_h ...
    
%[bp1x, bp1y, bp1h, bp2x, bp2y, bp2h, bp3x, bp3y, bp3h, bp4x, bp4y, bp4h, bp5x, bp5y, bp5h, bp6x, bp6y, bp6h, bp7x, bp7y, bp7h, bp8x, bp8y, bp8h] = importDeepLabCutfile(deeplabcutfile, 4, 1000);
x5 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 2};
x2 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 5};
x3 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 8};
x4 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 11};
x1 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 14};
x6 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 17};
x7 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 20};
x8 = HK20190528151044sidedalotia1DeadliomstumpRightt1DeepCutresnet50{:, 23};
%[bodyparts, bp1_x, bp_1y, bp1_lh, bp2_x, bp2_ym bp2_lh] = importDeepLabCutfile(deeplabcutfile, 4, 1000);
fileName = strcat(TaskName,'_',deeplabcutfile);

% Compute Projections Matrix: (put in your body parts list!)
AllBodyparts = horzcat(x1, x2, x3, x4, x5, x6, x7, x8);
% align to a set bodypart, here "bp1":
AllBodypartsMinusOne = horzcat(x2-x1, x3-x1, x4-x1, x5-x1, x6-x1, x7-x1, x8-x1);

% Set which projections to use: 
Data = AllBodypartsMinusOne;
fprintf(1, 'Check that the data you want is selected!')

%%

%define any desired parameter changes here
parameters.embedding_batchSize = 2000; 
parameters.trainingSetSize = 1000;
parameters.numProcessors = 8; %8; %4
parameters.displayAlignmentExample = false;
parameters.samplingFreq = 100; %30
parameters.pcaModes = 50;

 %2^H (H is the transition entropy)
parameters.perplexity = 20; %32

%relative convergence criterium for t-SNE
parameters.relTol = 1e-4;

%number of dimensions for use in t-SNE
parameters.num_tsne_dim = 2;

numZeros = 1;

%initialize parameters
parameters = setRunParameters(parameters);
load('saved_colormaps','cc','cc2')

%set frames to use (default is to use all frames)
firstFrame = 1;
lastFrame = [];


projectionsDirectory = [filePath slashVal() 'projections' slashVal()];
if ~exist(projectionsDirectory,'dir')
    mkdir(projectionsDirectory);
end

L = length(Data); %length of data... 

projections = Data;


if parameters.pcaModes > length(projections(1,:))
    parameters.pcaModes = length(projections(1,:));
end

fileNum = [repmat('0',1,numZeros-length(num2str(i))) num2str(i)];
save([projectionsDirectory 'projections_' fileNum '.mat'],'projections','fileName');

figure
N = length(projections(:,1));
plot((1:N)./parameters.samplingFreq,projections(:,:),'linewidth',1)
q=regexp(num2str(1:10),' ','split');q = q(returnCellLengths(q)>0);
legend(q,'fontsize',16,'fontweight','bold')
set(gca,'fontsize',14,'fontweight','bold')
xlabel('Time (s)','fontsize',16,'fontweight','bold')
ylabel('Projection','fontsize',16,'fontweight','bold')
xlim([0 N/parameters.samplingFreq]);

    
%% t-SNE embedding

fprintf(1,'Calculating Wavelet Transform\n');
[data,f] = findWavelets(projections,parameters.pcaModes,parameters);   

amps = sum(data,2);
data(:) = bsxfun(@rdivide,data,amps);

skipLength = round(length(data(:,1))/parameters.trainingSetSize);
if skipLength < 5
    skipLength = 5;
end

trainingSetData = data(skipLength:skipLength:end,:);
trainingAmps = amps(skipLength:skipLength:end);
parameters.signalLabels = log10(trainingAmps);

% I am not doing a split/train, I run t-SNE and embedding on all the data: 

%fprintf(1,'Finding t-SNE Embedding for Training Set\n');
%figure
[trainingEmbedding,betas,P,errors] = run_tSne(trainingSetData,parameters);

fprintf(1,'Finding t-SNE Embedding for all Data\n');

%figure
%embeddingValues = cell(L,1);
%i=1;
%[embeddingValues{i},~] = run_tSne(data,parameters);

i=1;
[embeddingValues{i},~] = findEmbeddings(data,trainingSetData,trainingEmbedding,parameters);



%% Make density plots

if isunix
    addpath(genpath('./utilities/'));
    addpath(genpath('./t_sne/'));
else
    addpath(genpath('t_sne'));
    addpath(genpath('utilities'));
end

maxVal = max(max(abs(combineCells(embeddingValues))));
maxVal = round(maxVal * 1.3);

sigma = maxVal / 15;
numPoints = 501;
rangeVals = [-maxVal maxVal];

[xx,density] = findPointDensity(combineCells(embeddingValues),sigma,numPoints,rangeVals);


figure
maxDensity = max(density(:));
imagesc(xx,xx,density)
axis equal tight off xy
caxis([0 maxDensity * .8])
colormap(cc)
colorbar
set(gca,'fontsize',14,'fontweight','bold')


LL = watershed(-density,8);
LL(density < 1e-6) = 0;
a = setdiff(unique(LL),0);
for i=1:length(a)
    LL(LL==a(i)) = i;
end
savefig(strcat(fileName,'_density_map.fig'))

figure
subplot(1,2,1)
imagesc(xx,xx,density)
caxis([0 maxDensity * .8])
axis equal tight off xy
hold on
set(gca,'fontsize',16,'fontweight','bold')

subplot(1,2,2)
imagesc(xx,xx,LL)
axis equal tight off xy
hold on
colormap(cc)

numRegions = max(LL(:));
Bs = cell(numRegions,1);
for i=1:numRegions
    
    B = bwboundaries(LL==i);
    subplot(1,2,1)
    plot(xx(B{1}(:,2)),xx(B{1}(:,1)),'k-','linewidth',2)
    
    subplot(1,2,2)
    plot(xx(B{1}(:,2)),xx(B{1}(:,1)),'k-','linewidth',2)
    
    Bs{i} = B{1};
    
    [ii,jj] = find(LL==i);
    medianX = xx(round(median(jj)));
    medianY = xx(round(median(ii)));
    text(medianX,medianY,num2str(i),'backgroundcolor','k','color','w','fontweight','bold','fontsize',12)
   
end

zValues = combineCells(embeddingValues);
N = length(zValues(:,1));

[regionValues,v,obj,pRest] = findWatershedRegions(zValues,xx,LL,[],[],[]);

save([projectionsDirectory 'region_matrix.mat'],'regionValues');

ethogram = zeros(N,numRegions+1);
for i=1:N
    ethogram(i,regionValues(i)+1) = regionValues(i);
end
savefig(strcat(fileName,'_Ethogram.fig'))



figure
imagesc((1:N)./parameters.samplingFreq,0:numRegions,ethogram')
colormap(cc)
caxis([0 numRegions]);
hold on
axis xy
for i=0:numRegions
    p=plot([0 N/parameters.samplingFreq],double(i)-.5+zeros(1,2),'k-')
end

CC2 = bwconncomp(regionValues == 0);
for i=1:CC2.NumObjects
    ii = CC2.PixelIdxList{i}(1)/parameters.samplingFreq;
    Q =  length(CC2.PixelIdxList{i})/parameters.samplingFreq;
    rectangle('Position',[ii -.5 Q 1],'facecolor','k')
end
xlim([0 N/parameters.samplingFreq]);
set(gca,'ytick',0:numRegions,'fontsize',0.1,'fontweight','bold','ticklength',[0 0])

%xlabel('Time (s)','fontsize',18,'fontweight','bold')
%ylabel('Behavior #','fontsize',18,'fontweight','bold')
%title('Ethogram','fontsize',22,'fontweight','bold')


if parameters.numProcessors > 1
    delete(gcp('nocreate'));
end

savefig(strcat(fileName,'_Region_map.fig'))

saveas(gcf, strcat(fileName,'_Region_map.png'))

%% Make Ethogram + projections + embedding in single figure

trailLength = 10; %default = 10..

figure
set(gcf, 'color','w')
for j=1:4:N
    

    %middle panel:
    subplot(3,3,5) %[2 5 8]
    N = length(projections(:,1));
    for i=0:numRegions
        plot((1:N)./parameters.samplingFreq,projections(:,:),'linewidth',1)
    end
    q=regexp(num2str(1:10),' ','split');q = q(returnCellLengths(q)>0);
    xlabel('Time (s)','fontsize',10,'fontweight','bold')
    axis  tight %off %equal
    colormap gray
    freezeColors
    y = ylim;
    hold on
    plot(j/parameters.samplingFreq + [0 0],y,'k-','linewidth',2)
    hold off 
    
    %first panel (ethogram):
    subplot(3,3,4)
    imagesc((1:N)./parameters.samplingFreq,0:numRegions,ethogram')
    colormap(cc)
    caxis([0 numRegions]);
    hold on
    axis xy
    for i=0:numRegions
        plot([0 N/parameters.samplingFreq],double(i)-.5+zeros(1,2),'k-')
    end
    
    CC2 = bwconncomp(regionValues == 0);
    for i=1:CC2.NumObjects
        ii = CC2.PixelIdxList{i}(1)/parameters.samplingFreq;
        Q =  length(CC2.PixelIdxList{i})/parameters.samplingFreq;
        rectangle('Position',[ii -.5 Q 1],'facecolor','k')
    end
    y = ylim;
    plot(j/parameters.samplingFreq + [0 0],y,'k-','linewidth',2)
    
    xlim([0 N/parameters.samplingFreq]);
    set(gca,'ytick',0:numRegions,'fontsize',6,'ticklength',[0 0])
    
    xlabel('Time (s)','fontsize',10,'fontweight','bold')
    ylabel('Behavior #','fontsize',10,'fontweight','bold')
    
    hold off
    
    % last panel
    subplot(3,3,[3 6 9])
    imagesc(xx,xx,LL)
    hold on
    axis equal tight off xy
    for i=1:numRegions
        plot(xx(Bs{i}(:,2)),xx(Bs{i}(:,1)),'k-','linewidth',1)
    end
    
    if regionValues(j) ~= 0
        plot(xx(Bs{regionValues(j)}(:,2)),xx(Bs{regionValues(j)}(:,1)),'k-','linewidth',3)
    end
    
    firstIdx = max([1 j-trailLength]);
    plot(zValues(firstIdx:j,1),zValues(firstIdx:j,2),'c-','linewidth',1)
    plot(zValues(j,1),zValues(j,2),'ko','MarkerFaceColor','m','MarkerSize',10)
    
    hold off
    
    drawnow
    
    if j==1
        pause
    end
    
end


print(strcat(fileName,'_SummaryFig.pdf'), '-dpdf')



%% close all 

clc
clear 
close all

