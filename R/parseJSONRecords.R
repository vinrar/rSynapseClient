## Parse JSON records to a table
## 
## Author: Matthew D. Furia <matt.furia@sagebase.org>
##############################################################################

.parseJSONRecords <- 
  function(json.list)
{
  resultsTable <- data.frame()
  for(i in seq_along(json.list)){
    thisRow <- .parseSingleRow(json.list[[i]])
    if(is.null(resultsTable)){
      resultsTable <- thisRow
    }else{
      resultsTable <- .rowMerge(resultsTable, thisRow)
    }
  }
  return(resultsTable)
}
