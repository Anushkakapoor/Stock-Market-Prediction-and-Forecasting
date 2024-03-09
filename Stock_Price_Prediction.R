library(rvest)
library(dplyr)
library(readr)
library(tidyr)

## Scraping data from sp500 website and yahoo finance

sp500_url <- "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"

sp500 <- read_html(sp500_url) %>% 
  html_node("table") %>% 
  html_table()

sp500 <- sp500 %>% select(Symbol, Security, `GICS Sector`, `GICS Sub-Industry`, `Headquarters Location`)

#Renaming the column names for better understanding
names(sp500) <- c("Ticker", "Name", "Sector", "Industry", "HQ_Location")

#saving the create data
save(sp500, file = "sp500.RData")

msft <- read_csv("https://query1.finance.yahoo.com/v7/finance/download/MSFT?period1=1585699200&period2=1699920000&interval=1d&events=history&includeAdjustedClose=true")
aapl <- read_csv("https://query1.finance.yahoo.com/v7/finance/download/AAPL?period1=1585699200&period2=1699920000&interval=1d&events=history&includeAdjustedClose=true")
mode(msft)

#BRK.B <- try(read_csv("https://query1.finance.yahoo.com/v7/finance/download/BRK.B?period1=1585699200&period2=1699920000&interval=1d&events=history&includeAdjustedClose=true"))
#mode(BRK.B)

#creating an empty data frame to store data fetched from yahoo finance 
returns <- as.data.frame(matrix(NA, ncol = 8, nrow = 0))
names(returns) <- c("Date", "Open", "High", "Low", "Close", "Adj_Close", "Volume", "Ticker")

#loop to iterate through the list of tickers under sp500 and getting data
#for each of those ticker into our newly created returns data frame
for(symbol in sp500$Ticker){
  print(symbol)
  url <- paste0("https://query1.finance.yahoo.com/v7/finance/download/", symbol, "?period1=1585699200&period2=1699920000&interval=1d&events=history&includeAdjustedClose=true")
  print(url)
  
  ret <- try(read_csv(url))
  
  if(mode(ret) != "character"){
    ret$Ticker <- symbol
    returns <- rbind(returns, ret)
  }
}

View(returns)
View(returns_long)
View(sp500)
View(returns_sp500)


#renaming the column names again as it got changed when scrapping data from yahoo finance.
names(returns) <- c("Date", "Open", "High", "Low", "Close", "Adj_Close", "Volume", "Ticker")

#converting all column values to numeric
returns <- returns %>% mutate(
  Open = as.numeric(Open),
  High = as.numeric(High),
  Low = as.numeric(Low),
  Close = as.numeric(Close),
  Adj_Close = as.numeric(Adj_Close),
  Volume = as.numeric(Volume)
)
#determining the movement of the stock price in a day by comparing open and close price.
returns <- returns %>% mutate(
  Movement = ifelse(Close > Open, "Up", "Down")
)

returns_long <- returns %>% gather("Series", "Value", -Date, -Ticker, -Movement)
save(returns_sp500, file = "returns_long.RData")
save(returns, file = "returns.RData")

# combining stock technical and fundamental information into one data frame for a more informative plotting data
returns_sp500 <- returns %>% left_join(sp500 %>% select(Ticker, Name, Sector, Industry), 
                                       by = c("Ticker" = "Ticker"))

#View(returns)
#View(returns_long)
#View(returns_sp500)

save(returns_sp500, file = "returns_sp500.RData")

