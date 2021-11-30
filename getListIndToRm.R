#!/aplic/R/Rscript

usage="listInds pop iter output"

parameters=commandArgs(trailingOnly=T)

if(length(parameters)!=3){
	stop(usage)
}else{
	inF<-parameters[1]
	famF<-parameters[2]
	outF<-parameters[3]
}


###weird stuff going on with read.csv
####obliged to do this crazy crappy stuff (friday night want it to work NOW...
#a=read.csv(inF,header=F,sep="\t",stringsAsFactors=F)
temp<-readLines(inF)
if(length(temp)==0){
	system(paste("echo NONE > ",outF))
	print("NO INDIVIDUAL TO REMOVE")
}else{
	fam<-read.table(famF,stringsAsFactors=F,header=F)
	maxCols=-Inf
	for(i in c(1:length(temp))){
		t<-strsplit(temp[i],split="\t")[[1]]
		maxCols<-max(c(maxCols,as.numeric(t[2])))
	}
	a<-data.frame(matrix("",nrow=length(temp),ncol=maxCols+2),stringsAsFactors=F)
	print(dim(a))
	for(i in c(1:length(temp))){
		t<-strsplit(temp[i],split="\t")[[1]]
		#t<-as.character(t)
		num<-as.numeric(t[2])
		#print(t)
		if(num<maxCols){
			a[i,]<-c(t,rep("",maxCols-num))
		}else{
			a[i,]<-t
		}
	}

	table<-data.frame(matrix(0,ncol=dim(a)[1]+1,nrow=dim(a)[1]),stringsAsFactors=F)
	names(table)<-c(a[,1],"total")
	a[,2]<-as.numeric(a[,2])
	row.names(table)<-c(a[,1])

	for(i in c(1:dim(a)[1])){
		for(j in c(1:a[i,2])){
			table[ a[i,1],a[i,j+2] ]<-1
		}
	}

	table$total=Inf
	list<-c()
	while( dim(table)[1] > 1 & sum(table$total)!=0){
		table$total<-apply(table[,names(table)!="total"],1,sum)
		ind=names(table)[table$total==max(table$total)][1]
		#print(table)
		#print(list)
		pop=fam$V1[ fam$V2==ind]
		if(length(pop) >1){
			stop(paste(ind,"is duplicated in your fam files...Te la mamaste guey!"))
		}
		list<-rbind(list,c(pop,ind))
		table<-table[row.names(table)!=ind,names(table)!=ind]
	}
	print(list)
	write.table(list,outF,quote=F,col.names=F,row.names=F,sep="\t",append=TRUE)
}

