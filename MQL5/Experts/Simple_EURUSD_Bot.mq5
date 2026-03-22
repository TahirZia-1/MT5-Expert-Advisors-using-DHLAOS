//+------------------------------------------------------------------+
//|                                        Simple_EURUSD_Bot.mq5 |
//|                                  Copyright 2025, Simple Bot |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Simple Bot"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Simple EUR/USD Bot - Guaranteed to Trade"

//--- Input parameters
input double   LotSize = 0.01;              // Lot size
input int      StopLoss = 50;               // Stop Loss in points
input int      TakeProfit = 100;            // Take Profit in points
input int      RSI_Period = 14;             // RSI period
input int      RSI_Oversold = 30;           // RSI oversold level
input int      RSI_Overbought = 70;         // RSI overbought level
input int      MinutesWait = 30;            // Minutes to wait between trades

//--- Global variables
int h_RSI;
double rsi_buffer[];
datetime last_trade_time = 0;
int magic_number = 54321;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize RSI indicator
    h_RSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    
    if(h_RSI == INVALID_HANDLE)
    {
        Print("Error creating RSI indicator");
        return INIT_FAILED;
    }
    
    ArraySetAsSeries(rsi_buffer, true);
    
    Print("Simple EUR/USD Bot initialized - WILL TRADE!");
    Print("Bot will trade when RSI < ", RSI_Oversold, " (BUY) or RSI > ", RSI_Overbought, " (SELL)");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    IndicatorRelease(h_RSI);
    Print("Simple EUR/USD Bot stopped");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get current time
    datetime current_time = TimeCurrent();
    
    // Wait between trades
    if(current_time - last_trade_time < MinutesWait * 60)
        return;
    
    // Don't trade if we already have open positions
    if(CountOpenPositions() > 0)
        return;
    
    // Get RSI value
    if(CopyBuffer(h_RSI, 0, 0, 2, rsi_buffer) < 2)
    {
        Print("Error getting RSI data");
        return;
    }
    
    double current_rsi = rsi_buffer[0];
    
    Print("Current RSI: ", DoubleToString(current_rsi, 2));
    
    // BUY signal - RSI oversold
    if(current_rsi < RSI_Oversold)
    {
        Print("BUY SIGNAL! RSI = ", DoubleToString(current_rsi, 2), " (below ", RSI_Oversold, ")");
        OpenTrade(ORDER_TYPE_BUY);
        return;
    }
    
    // SELL signal - RSI overbought  
    if(current_rsi > RSI_Overbought)
    {
        Print("SELL SIGNAL! RSI = ", DoubleToString(current_rsi, 2), " (above ", RSI_Overbought, ")");
        OpenTrade(ORDER_TYPE_SELL);
        return;
    }
    
    // If no signal, print waiting message every 10 minutes
    static datetime last_status = 0;
    if(current_time - last_status > 600) // 10 minutes
    {
        Print("Waiting for signal... RSI = ", DoubleToString(current_rsi, 2), 
              " (Need < ", RSI_Oversold, " for BUY or > ", RSI_Overbought, " for SELL)");
        last_status = current_time;
    }
}

//+------------------------------------------------------------------+
//| Open a trade                                                     |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE order_type)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    double price, sl, tp;
    
    if(order_type == ORDER_TYPE_BUY)
    {
        price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        sl = price - StopLoss * _Point;
        tp = price + TakeProfit * _Point;
    }
    else
    {
        price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        sl = price + StopLoss * _Point;
        tp = price - TakeProfit * _Point;
    }
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = LotSize;
    request.type = order_type;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = magic_number;
    request.comment = "Simple Bot";
    request.deviation = 10;
    
    if(OrderSend(request, result))
    {
        if(result.retcode == TRADE_RETCODE_DONE)
        {
            Print("SUCCESS! ", EnumToString(order_type), " trade opened at ", price);
            Print("Stop Loss: ", sl, ", Take Profit: ", tp);
            last_trade_time = TimeCurrent();
        }
        else
        {
            Print("Trade failed with error: ", result.retcode, " - ", result.comment);
        }
    }
    else
    {
        Print("OrderSend failed with error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Count open positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == magic_number)
            {
                count++;
            }
        }
    }
    
    return count;
}