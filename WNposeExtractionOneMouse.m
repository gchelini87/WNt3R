%This is the first step of WNt3R; declare subject ID as a string first, then launch. 
%You'll need to load the CSV-data  obtained from deeplabcut for the given animal. Make sure you have 1 video for each
%trial of the experiment and 1 corresponding CSV file.
%This step takes about 5-10 minutes and automatically extrapolates the
%meanigful body postures for the declared animal.
%Postures are then plotted on a scatter plot and can be inspected by the
%user 

%Declare Mouse Name first (as a string)
Mouse='058'

%Import data from CSV file. Copy full path and file name
[OFname,folderOF]=uigetfile(); FindOF=fullfile(folderOF,OFname);
[SHAMname,folderSHAM]=uigetfile(); FindSHAM=fullfile(folderSHAM,SHAMname);
[T1name,folderT1]=uigetfile(); FindT1=fullfile(folderT1,T1name);
[T2name,folderT2]=uigetfile(); FindT2=fullfile(folderT2,T2name);
[T3name,folderT3]=uigetfile(); FindT3=fullfile(folderT3,T3name);

OF=readmatrix(FindOF);
SHAM=readmatrix(FindSHAM);
T1=readmatrix(FindT1);
T2=readmatrix(FindT2);
T3=readmatrix(FindT3);

%Create Matrix to work with
OFy=[OF(1:4500,3:3:end)];
SHAMy=[SHAM(1:4500,3:3:end)];
T1y=[T1(1:4500,3:3:end)];
T2y=[T2(1:4500,3:3:end)];
T3y=[T3(1:4500,3:3:end)];
ThisMouseY=cat(1,OFy,SHAMy,T1y,T2y,T3y);

ThisMouseY=fillmissing(ThisMouseY,'previous'); % Replace the gaps (NaN cells) with closest value in the column

FramesOFy=(1:length(OFy))';
FramesSHAMy=(1:length(SHAMy))';
FramesT1y=(1:length(T1y))';
FramesT2y=(1:length(T2y))';
FramesT3y=(1:length(T3y))';
FramesThisMouse=cat(1,FramesOFy,FramesSHAMy,FramesT1y,FramesT2y,FramesT3y);

ThisMouse=cat(1,OF(1:4500,:),SHAM(1:4500,:),T1(1:4500,:),T2(1:4500,:),T3(1:4500,:));
ThisMouse(1:length(ThisMouse),1:1)=FramesThisMouse;

clear FramesSHAMy FramesT1y SHAM FramesT2y T2 FramesT3y T3 T1 folderSHAM folderT1 folderT2 folderT3

%Calculate Body-parts distances for the Y coordinates

%First assign each matrix column to a vector, easier to handle
Nose=ThisMouseY(1:length(ThisMouseY),1:1);
Eyes=ThisMouseY(1:length(ThisMouseY),2:2);
Neck=ThisMouseY(1:length(ThisMouseY),3:3);
MidBack=ThisMouseY(1:length(ThisMouseY),4:4);
LowBack=ThisMouseY(1:length(ThisMouseY),5:5);
Tail=ThisMouseY(1:length(ThisMouseY),6:6);

DistMatrix=[Nose-Eyes,Nose-Neck,Nose-MidBack,Nose-LowBack,Nose-Tail,Eyes-Neck,Eyes-MidBack,Eyes-LowBack,Eyes-Tail,Neck-MidBack,Neck-LowBack,Neck-Tail,MidBack-LowBack,MidBack-Tail,LowBack-Tail];

clear Nose Eyes Neck MidBack LowBack Tail

% TIME FOR CLUSTERING                             
Elbow=kmeans_opt(DistMatrix);  %K-mean clustering using Elbow method to determine optilan number (UNSUPERVISED)
Clusters=unique(Elbow);
for i=1:length(Clusters);
    counts(i)=sum(Elbow==Clusters(i));
end

clear i

%POSTURE DETERMINATION
%Now that the clustering is done, assign each original observation to a
%cluster 
 ClusterSummary=[Clusters, counts'];                  %Recall number of Frames per Cluster
 ClusteredDist=[FramesThisMouse,DistMatrix,Elbow];    %Distance matrix with Frames and Clusters
 ClusteredYData=[FramesThisMouse,ThisMouseY,Elbow];   %Original Coordinates with Clusters assigned
 ThisMouseClustered=[ThisMouse,Elbow];                %Original DLC output with Clusters assigned
 ClusteredOF=[ClusteredYData(1:4500,:)]; 
 ClusteredSHAM=[ClusteredYData(4501:9000,:)];            %Original Y Coordinates with cluster assigned for SHAM only
 ClusteredT1=[ClusteredYData(9001:13500,:)];            %Original Y Coordinates with cluster assigned for Trial 1 only
 ClusteredT2=[ClusteredYData(13501:18000,:)];            %Original Y Coordinates with cluster assigned for Trial 1 only
 ClusteredT3=[ClusteredYData(18001:end,:)];            %Original Y Coordinates with cluster assigned for Trial 1 only
 
figure ('Name','OF poses overtime')
scatter(ClusteredOF(:,1),ClusteredOF(:,8));
figure ('Name','SHAM poses overtime')
scatter(ClusteredSHAM(:,1),ClusteredSHAM(:,8));
figure ('Name','Trial1 poses overtime')
scatter(ClusteredT1(:,1),ClusteredT1(:,8));
figure ('Name','Trial2 poses overtime')
scatter(ClusteredT2(:,1),ClusteredT2(:,8));
figure ('Name','Trial3 poses overtime')
scatter(ClusteredT3(:,1),ClusteredT3(:,8));
 
 
clear counts  FramesThisMouse i SHAMy T1y T2y T3y DistMatrix FindSHAM FindT1 FindT2 FindT3
 
%Starting From the ClusteredData matrix extract each single cluster and plot
%the corresponding posture on a scatter plot

for Cluster2Explore=1:length(ClusterSummary);
    num=length(ClusteredYData);
    ClusterIndex=0;

for ind=1:num;
   if ClusteredYData(ind,8)==Cluster2Explore;
       ClusterIndex=(ClusterIndex+1);
        Cluster(ClusterIndex,1:8)=ClusteredYData(ind,1:8);

   end
end
     NameCluster=string(num2let(Cluster2Explore));
     assignin('base',NameCluster,Cluster);
     ClusterMean=[mean(Cluster(:,2:7))];
     
     %Create a Representative Scatter Plot for the Cluster just analyzed
     figure('Name',NameCluster);
     Ycoord=[ClusterMean/-1];
     Xcoord=[1:6];            
     plot(Xcoord,Ycoord,'-x');
     
     ClusterIndex=(ClusterIndex+1);
     AllClustersMean(Cluster2Explore,:)=mean(Cluster(:,2:end));
     clear Cluster
end

%Average the ClusteredDist Matrix for future analysis
for DistIndex=1:length(ClusterSummary);
    [Dist2Avg]=find(ClusteredDist(:,17)==DistIndex);
    toAVG=[ClusteredDist(Dist2Avg,2:16)];
    ClusteredDistMeans(DistIndex,:)=[mean(toAVG),DistIndex];
end

%Create a string vetor with the Animal Code to include with the Cluster
%Mean Summary
code=strings(length(AllClustersMean),1);
code(:)=[SHAMname(1:3)];

%Generate Cluster Mean Summary for both Ycoordinates and Distances
AllClustersMean=[code,AllClustersMean,ClusterSummary(:,2:end)];
ClusteredDistMeans=[code,ClusteredDistMeans];

AllClustersMean(1:end,1:1)=Mouse;    %Assign the Mouse Identity to the first column of the matrix
ClusteredDistMeans(1:end,1:1)=Mouse; 

%Print Outcome in CSV files
writematrix(AllClustersMean, 'MouseXCoordMeans.csv');
writematrix(ClusteredDistMeans, 'MouseXDistMeans.csv');
writematrix(ClusteredYData, 'ClusteredXData.csv');
writematrix(ClusteredOF, 'ClusteredOF.csv');
writematrix(ClusteredSHAM, 'ClusteredSham.csv');
writematrix(ClusteredT1, 'ClusteredT1.csv');
writematrix(ClusteredT2, 'ClusteredT2.csv');
writematrix(ClusteredT3, 'ClusteredT3.csv');
writematrix(ClusteredDist, 'ClusteredXDist.csv');
writematrix(ThisMouseClustered, 'MouseXClustered.csv');

%Eliminate unwanted variables
clear ans ind num ClusterIndex Xcoord Ycoord Cluster2Explore NameCluster NameCluster ClusterMean toAVG Dist2Avg code T1name T2name T3name SHAMname OFname DistIndex

%Print Clusters into CSV files
writematrix(a, 'C1.csv');
writematrix(b, 'C2.csv');
writematrix(c, 'C3.csv');
writematrix(d, 'C4.csv');
writematrix(e, 'C5.csv');
writematrix(f, 'C6.csv');
writematrix(g, 'C7.csv');
writematrix(h, 'C8.csv');
writematrix(i, 'C9.csv');
writematrix(j, 'C10.csv');
writematrix(k, 'C11.csv');
writematrix(l, 'C12.csv');
writematrix(m, 'C13.csv');
writematrix(n, 'C14.csv');
writematrix(o, 'C15.csv');
writematrix(p, 'C16.csv');
writematrix(q, 'C17.csv');
writematrix(r, 'C18.csv');
writematrix(s, 'C19.csv');
writematrix(t, 'C20.csv');
writematrix(u, 'C21.csv');
writematrix(v, 'C22.csv');
writematrix(w, 'C23.csv');
writematrix(x, 'C24.csv');
writematrix(y, 'C25.csv');
writematrix(z, 'C26.csv');



