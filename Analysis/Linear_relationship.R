
microb = read.table("/home/ratanond/Desktop/Masters_Project/Synthetic/Arghavan/MetaSample2/samples.txt")
microb = as.matrix(microb)
microb <- microb[,-1]
microb_rows = dim(microb)[1]/2  # divide by two to choose only the first class
microb = microb[1:microb_rows,] 
sd <- apply(microb,2,sd)
microb <- microb[,which(sd!=0)]  # choose only OTUs with non-zero standard deviation
## The top ten are 417 541  42 125 235 545 547 128 147 148 (from linear_adjust.R)
microb <- microb[,c(417,541,42,125,235,545,547,128,147,148)] # five OTUs with min numbers of zeros

gaussian = read.table("/home/ratanond/Desktop/Masters_Project/Synthetic/Eunji/rnaseq_cls/rnaseq_cls/out/params_sb_high_1_ma_trn.txt",sep = ",")
gaussian <- as.matrix(gaussian)
gaussian_rows <- dim(gaussian)[1]/2    # divide by two to choose only the first class
gaussian <- gaussian[1:gaussian_rows,1:300]

rnaseq = read.table("/home/ratanond/Desktop/Masters_Project/Synthetic/Eunji/rnaseq_cls/rnaseq_cls/out/params_sb_high_1_trn.txt",sep = ",")
rnaseq = as.matrix(rnaseq)
rnaseq_rows = dim(rnaseq)[1]/2   # divide by two to choose only the first class
rnaseq = rnaseq[1:rnaseq_rows,1:300]  

y <- microb[,1]
x1 <- gaussian[,1]
x2 <- gaussian[,2]
x3 <- gaussian[,3]
data = data.frame(y,x1,x2,x3)

# For small cases
microb1<-microb2<-microb3<-microb4<-microb5<-microb6<-microb7<-microb8<-microb9<-microb10<-microb
microb1[,1] <-predict(lm(y~x1,data = data, subset = y>0),newdata = as.data.frame(gaussian))
microb2[,1] <-predict(lm(y~x1+x2,data = data, subset = y>0),newdata = as.data.frame(gaussian))
microb3[,1] <-predict(lm(y~x1+x2+x3,data = data, subset = y>0),newdata = as.data.frame(gaussian))

####  for high number of n (large cases), use for-loop instead
exclude_list = microb[,-c(417,42,125,235,128)]
include_list = microb[,c(417,42,125,235,128)]
all_list = cbind(include_list,exclude_list)
my_microb = all_list[,1:11]
y <- microb[which(microb[,1]>0),1]
cor_g<-numeric(dim(gaussian)[2])
cor_rna<-numeric(dim(rnaseq)[2])
  for (n in 1:10){
    new_microb <- my_microb
    m <- lm(microb[,1:5]~gaussian[,1:n])
    new_microb[,1:5] <- predict(m, newdata=as.data.frame(gaussian))
    cor_g[n] <- myCCA(new_microb, gaussian)
    cor_rna[n] <- myCCA(new_microb,rnaseq)
  }
plot(cor_g[1:10],col="blue", main = "Multivariate Gaussian", ylab = "Canonical Correlation", xlab="Number of Genes Used")
plot(cor_rna[1:10],col="blue", main = "RNAseq", ylab = "Canonical Correlation", xlab="Number of Genes Used")

myCCA <- function(microb_new,gaussian) {
library(PMA)
set.seed(1105)
ccaPerm = CCA.permute(x = microb_new, z = gaussian,
                      typex = "standard", typez = "standard", 
                      nperms = 30, niter = 5, standardize = T,trace = F)
penXtemp = ccaPerm$bestpenaltyx
penZtemp = ccaPerm$bestpenaltyz
ccaRslt = CCA(x = microb_new, z = gaussian,
              typex = "standard", typez = "standard",
              penaltyx = penXtemp, penaltyz = penZtemp,
              K = 2, niter = 5, standardize = T)
#sum(ccaRslt$u != 0)
#sum(ccaRslt$v != 0)

ccaScoreU = microb_new %*% ccaRslt$u
ccaScoreV = gaussian %*% ccaRslt$v
ccaScores = cbind(ccaScoreU, ccaScoreV)
colnames(ccaScores) = c("U1", "U2", "V1", "V2")
ccaScores = as.data.frame(ccaScores)
return(cor(ccaScores$U1,ccaScores$V1))
}

gaussian_list = numeric(dim(microb)[2])
for (i in 2:dim(microb)[2]) {
  cca_list[i] <- myCCA(microb[,1:i],gaussian)
}
rna_list = numeric(dim(microb)[2])
for (i in 2:dim(microb)[2]) {
  rna_list[i] <- myCCA(microb[,1:i],rnaseq)
}
df = data.frame(cca_list,rna_list)
df = df[-1,]
dff = cbind(df[,1:2],df[,1:2])
