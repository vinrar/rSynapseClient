## Prompt the user for login credentials
## 
## Author: Matthew D. Furia <matt.furia@sagebase.org>
###############################################################################

.tkGetCredentials <- function(credentials, imageFile = .getCache("synapseBannerPath")){
  title = "Welcome! Please login."
  
  ## tk doesn't like NULLs
  if(is.null(title))
    title <- ""
  if(is.null(credentials$username))
    credentials$username <- ""
  
  ## set up toplevel widget
  root <- tcltk::tktoplevel()
  tcltk::tktitle(root) <- title
  
  ## set up variables to catch username and password
  ## initialize username to the passed value
  userNameVar <- tcltk::tclVar(credentials$username)
  passwordVar <- tcltk::tclVar("")
  
  checkState <- 
    function()
  {
    if(checkUserNameState() && tcltk::tclvalue(passwordVar) != ""){
      tcltk::tkconfigure(loginButton, state="normal")
      tcltk::tkbind(passwordEntryWidget, "<Return>", onLogin)
    }else{
      tcltk::tkconfigure(loginButton, state="disabled")
      tcltk::tkbind(passwordEntryWidget, "<Return>", NULL)
    }
  }
  checkUserNameState <-
    function()
  {
    kEmailPattern <- "^.+@.+[\\.][[:alpha:]]+[\\+[[:graph:]]+]?$"
    ## make sure username looks like an email address
    if(regexpr(kEmailPattern, tcltk::tclvalue(userNameVar)) > 0){
      ## TODO: set checkbox
      return(TRUE)
    }
    ## unset checkbox
    return(FALSE)
  }
  
  
  ## Text Entry Widgets for username and password. The password entry hides input
  usernameEntryWidget <- tcltk::tkentry(root, textvariable = userNameVar)
  passwordEntryWidget <- tcltk::tkentry(root, textvariable = passwordVar, show = "*")
  
  ## Event handlers for OK and Cancel buttons
  onLogin <- 
    function()
  {
    credentials$username <<- tcltk::tclvalue(userNameVar)
    credentials$password <<- tcltk::tclvalue(passwordVar)
    tcltk::tkgrab.release(root)
    tcltk::tkdestroy(root)
  }
  onCancel <- 
    function()
  {
    credentials <<- NULL
    tcltk::tkgrab.release(root)
    tcltk::tklower(root)
    tcltk::tkdestroy(root)
  }
  onDestroy <- 
    function() 
  {
    tcltk::tklower(root)
    tcltk::tkgrab.release(root)
  }
  
  ## OK and Cancel buttons. disable cancel button until both username and login
  ## fields contain entries
  loginButton <- tcltk::tkbutton(root, text=" Login  ", command=onLogin, state="disabled")
  cancelButton <- tcltk::tkbutton(root, text=" Cancel ", command=onCancel)
  tcltk::tkbind(cancelButton, "<Return>", onCancel)
  
  image <- tcltk::tcl("image", "create", "photo", image, file=imageFile)
  imageLabel <- tcltk::tklabel(root, image=image, bg="white")
  tcltk::tkgrid(imageLabel, column=0, row=0, columnspan=4)
  
  ## the first row is for username
  tcltk::tkgrid(tcltk::tklabel(root,text="Email Address", justify='right'), column=0, row=1, sticky="e", padx=c(0,5), pady=c(12,5))
  tcltk::tkgrid(usernameEntryWidget, column=1, row=1,sticky="nsew", padx=c(0,5), columnspan=3, pady=c(12,5))
  
  ## the second row is for password
  tcltk::tkgrid(tcltk::tklabel(root, text="Password", justify='right'), column=0, row=2, sticky="e", padx=c(0,5), pady=c(0,12))
  tcltk::tkgrid(passwordEntryWidget, column=1, row=2, sticky="nsew", padx=c(0,5), columnspan=3,  pady=c(0,12))
  
  ## the third row is for the Login and Cancel buttons
  tcltk::tkgrid(loginButton, column=1, row=3, pady=c(0,5))
  tcltk::tkgrid(cancelButton, column=2, row=3, pady=c(0,5))
  
  ## bind the return key to onLogin function when in the passwordEntry widget and to
  ## set focus to the password entry widget when in the ussername entry widget
  tcltk::tkbind(usernameEntryWidget, "<Return>", function(){tcltk::tkfocus(passwordEntryWidget)})
  tcltk::tkbind(usernameEntryWidget, "<KeyRelease>", checkState)
  tcltk::tkbind(passwordEntryWidget, "<KeyRelease>", checkState)
  
  ## fix the size of the login window
  tcltk::tkwm.resizable(root,FALSE, FALSE)
  
  ## set the focus to the root widget
  tcltk::tkraise(root)
  tcltk::tkgrab.set(root)
  if(credentials$username == ""){
    tcltk::tkfocus(usernameEntryWidget)
  }else{
    tcltk::tkfocus(passwordEntryWidget)
  }
  
  ## bind the destroy method
  tcltk::tkbind(root, "<Destroy>", onDestroy)
  
  ## wait for user input
  tcltk::tkwait.window(root)
  
  ## return the credentials
  credentials
}

.terminalGetCredentials <- function(credentials){
  if(is.null(credentials$username))
    credentials$username <= ""
  
  if(credentials$username == "")
    credentials$username <- .getUsername()
  credentials$password <- .getPassword()
  
  credentials
}

.getUsername <- function(){
  readline(prompt="Username: ")
}

.getPassword <- function(){
  ## Currently only suppresses output in unix-like terminals
  
  finallyCmd <- NULL
  if(tolower(.Platform$GUI) == "x11"){
    if(tolower(.Platform$OS.type) == "unix"){
      ## this is a unix terminal
      system("stty -echo")
      finallyCmd <- "stty echo"
    }
  }else if(tolower(.Platform$GUI) == "rterm"){
    if(tolower(.Platform$OS.type) == "windows"){
      ## this is a windows terminal
      ## TODO figure out how to suppress terminal output in Windows
    }	
  }
  
  tryCatch(
    password <- readline(prompt="Password: "),
    finally={
      if(!is.null(finallyCmd)){
        system(finallyCmd) ## turn echo back on only if it was turned off
        cat("\n")
      }
    }
  )
  return(password)
}

.hasTk <- function(){
  if(is.null(.getCache("useTk"))){
    ## check to see if the system has a working tk installation
    origWarn <- options()$warn
    options(warn=-1)
    tryCatch({
        root <- tcltk::tktoplevel()
        .setCache("useTk", TRUE)
      },
      error = function(e){
        msg <- "tcl/tk does not seem to be installed on your system. The GUI login widget has been disabled."
        warning(msg, .call=FALSE)
        .setCache("useTk", FALSE)
      },
      warning = function(e){
        msg <- "tcl/tk does not seem to be installed on your system. The GUI login widget has been disabled."
        warning(msg, .call=FALSE)
        .setCache("useTk", FALSE)
      },
      finally={
        tryCatch(
          tcltk::tkdestroy(root),
          error = function(e){warning(e)}
        )
        options(warn=origWarn)
      }
    )
  }
  .getCache("useTk")
}
