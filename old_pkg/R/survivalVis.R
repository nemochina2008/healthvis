#' This function creates an interactive survival plot 
#'
#' \code{survivalVis} creates an interactive survival plot
#' 
#'
#' @param cobj An object created with a call to \code{\link{coxph}}
#' @param plot.title The title of the plot to appear on the HTML page
#' @param data The dataset used to creat the coxph object. 
#' @param plot If TRUE a browser launches and displays the interactive graphic.
#' @return healthvisObj An object of class "healthvis" containing the HTML, Javascript,
#' and CSS code needed to generate the interactive graphic
#' @export

survivalVis <- function(cobj, data, plot.title="",plot=TRUE){
  
  if(class(cobj) != "coxph"){
    stop("Object not of class 'coxph'")
  }
  
  tmp.data <- data # In case we have to modify
  
  formula <- cobj$formula
  
  vars <- all.vars(formula[[3]]) # This is a list of all variables on RHS
  
  day.max <- max(data[[all.vars(formula[[2]])[1]]]) # This might need to be updated
  
  if(length(vars) > 10){
    stop("Number of covariates exceeds 10")
  }
  
  # Figure out what kind of menus are needed
  menu.type <- vector("character", length(vars))
  var.list <- list()
  ref.cats <- c()
  
  for(i in 1:length(vars)){
    cur <- tmp.data[[vars[i]]]
    if(class(cur) == "numeric" || class(cur) == "integer"){
      if(length(table(cur)) < 5){
        warning("Variable ", vars[[i]], " has fewer than 5 unique values; treating as continuous, but should this be a factor?")
      }
      menu.type[i] <- "continuous"
      var.list[[vars[i]]] <- range(cur)
    } else if(class(cur) == "factor"){
      if(length(levels(cur)) > 10){
        stop("Variable ", vars[[i]], " has too many levels (>10).")
      }
      menu.type[i] <- "factor"
      var.list[[vars[i]]] <- levels(cur)
      ref.cats <- c(ref.cats, paste(vars[i], levels(cur)[1], sep=""))
    }
  }
  
  ds <- tmp.data[1,] # Take the first row of data
  ds <- baseline(ds)
  so <- survfit(cobj, newdata=ds)
  
  dt <- coxph.detail(cobj)
  data <- cbind(so$time, -log(so$surv))
  colnames(data) <- c("time", "haz")
  data <- apply(data, 1, as.list)
  djs <- toJSON(data)
  
  c.sort <- c(cobj$coef, sapply(ref.cats, function(x){assign(x, 0)}))
  c.sort <- c.sort[sort(names(c.sort))]
  
  # Create the healthvis object
  healthvisObj <- list()
  class(healthvisObj) <- "healthvis"
  healthvisObj$type <- "survival"
  
  healthvisObj$var.type <- menu.type
  healthvisObj$var.list <- var.list
  healthvisObj$plot.title <- plot.title
  healthvisObj$page.html <- writePage(writeD3Survival(djs,c.sort,names(c.sort),vars,menu.type,day.max),
                                writeD3SurvivalCss(),var.type=healthvisObj$var.type,
                                var.list=healthvisObj$var.list,plot.title=healthvisObj$plot.title)
  if(plot){
    plot(healthvisObj)
  }
  return(healthvisObj)

}

baseline <- function(ds){
  for(i in 1:length(ds)){
    if(class(ds[1,i]) == "factor"){
      ds[1,i] <- levels(ds[1,i])[1]
    } else {
      ds[1,i] <- 0
    }
  }
  ds
}
