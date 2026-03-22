//+------------------------------------------------------------------+
//|                                            EURUSD_AI_Bot.mq5 |
//|                                  Copyright 2025, Your Name |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "AI Trading Bot for EUR/USD - Advanced Technical Analysis"

//--- Input parameters
input group "=== Trading Parameters ==="
input double   LotSize = 0.01;              // Lot size
input int      StopLoss = 50;               // Stop Loss in points
input int      TakeProfit = 100;            // Take Profit in points
input double   MaxRisk = 2.0;               // Maximum risk per trade (%)
input int      MaxTrades = 1;               // Maximum concurrent trades

input group "=== Technical Indicators ==="
input int      RSI_Period = 14;             // RSI period
input int      MA_Fast = 20;                // Fast MA period
input int      MA_Slow = 50;                // Slow MA period
input int      BB_Period = 20;              // Bollinger Bands period
input double   BB_Deviation = 2.0;          // Bollinger Bands deviation
input int      MACD_Fast = 12;              // MACD fast period
input int      MACD_Slow = 26;              // MACD slow period
input int      MACD_Signal = 9;             // MACD signal period

input group "=== Time Settings ==="
input int      StartHour = 8;               // Trading start hour (GMT)
input int      EndHour = 18;                // Trading end hour (GMT)
input bool     TradeOnFriday = false;       // Trade on Friday

input group "=== AI Settings ==="
input double   SignalStrength = 0.7;        // Minimum signal strength (0.0-1.0)
input bool     UseNewsFilter = true;        // Use news filter
input bool     UseTrendFilter = true;       // Use trend filter

//--- Global variables
int h_RSI, h_MA_Fast, h_MA_Slow, h_BB, h_MACD;
double rsi_buffer[], ma_fast_buffer[], ma_slow_buffer[];
double bb_upper[], bb_lower[], bb_middle[];
double macd_main[], macd_signal[];
datetime last_trade_time = 0;
int magic_number = 12345;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize indicators
    h_RSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    h_MA_Fast = iMA(_Symbol, PERIOD_CURRENT, MA_Fast, 0, MODE_SMA, PRICE_CLOSE);
    h_MA_Slow = iMA(_Symbol, PERIOD_CURRENT, MA_Slow, 0, MODE_SMA, PRICE_CLOSE);
    h_BB = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    h_MACD = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    
    // Check if indicators are created successfully
    if(h_RSI == INVALID_HANDLE || h_MA_Fast == INVALID_HANDLE || 
       h_MA_Slow == INVALID_HANDLE || h_BB == INVALID_HANDLE || h_MACD == INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return INIT_FAILED;
    }
    
    // Resize arrays
    ArraySetAsSeries(rsi_buffer, true);
    ArraySetAsSeries(ma_fast_buffer, true);
    ArraySetAsSeries(ma_slow_buffer, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(macd_main, true);
    ArraySetAsSeries(macd_signal, true);
    
    Print("EUR/USD AI Trading Bot initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up indicators
    IndicatorRelease(h_RSI);
    IndicatorRelease(h_MA_Fast);
    IndicatorRelease(h_MA_Slow);
    IndicatorRelease(h_BB);
    IndicatorRelease(h_MACD);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's a new bar
    static datetime last_bar_time = 0;
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if(last_bar_time == current_bar_time)
        return;
    
    last_bar_time = current_bar_time;
    
    // Check trading hours
    if(!IsTradingTime())
        return;
    
    // Update indicator values
    if(!UpdateIndicators())
        return;
    
    // Check for trading signals
    double signal_strength = CalculateSignalStrength();
    
    if(signal_strength >= SignalStrength)
    {
        int signal_type = GetTradeSignal();
        
        if(signal_type == 1 && CountTrades() < MaxTrades) // Buy signal
        {
            OpenTrade(ORDER_TYPE_BUY);
        }
        else if(signal_type == -1 && CountTrades() < MaxTrades) // Sell signal
        {
            OpenTrade(ORDER_TYPE_SELL);
        }
    }
    
    // Manage existing trades
    ManageTrades();
}

//+------------------------------------------------------------------+
//| Update all indicator values                                      |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    // Get RSI values
    if(CopyBuffer(h_RSI, 0, 0, 3, rsi_buffer) < 3)
        return false;
    
    // Get MA values
    if(CopyBuffer(h_MA_Fast, 0, 0, 3, ma_fast_buffer) < 3)
        return false;
    
    if(CopyBuffer(h_MA_Slow, 0, 0, 3, ma_slow_buffer) < 3)
        return false;
    
    // Get Bollinger Bands values
    if(CopyBuffer(h_BB, 0, 0, 3, bb_upper) < 3)
        return false;
    
    if(CopyBuffer(h_BB, 1, 0, 3, bb_middle) < 3)
        return false;
    
    if(CopyBuffer(h_BB, 2, 0, 3, bb_lower) < 3)
        return false;
    
    // Get MACD values
    if(CopyBuffer(h_MACD, 0, 0, 3, macd_main) < 3)
        return false;
    
    if(CopyBuffer(h_MACD, 1, 0, 3, macd_signal) < 3)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate signal strength (0.0 to 1.0)                         |
//+------------------------------------------------------------------+
double CalculateSignalStrength()
{
    double strength = 0.0;
    double weight_sum = 0.0;
    
    // RSI signal (weight: 0.25)
    if(rsi_buffer[0] < 30 || rsi_buffer[0] > 70)
        strength += 0.25;
    weight_sum += 0.25;
    
    // MA crossover signal (weight: 0.30)
    if((ma_fast_buffer[0] > ma_slow_buffer[0] && ma_fast_buffer[1] <= ma_slow_buffer[1]) ||
       (ma_fast_buffer[0] < ma_slow_buffer[0] && ma_fast_buffer[1] >= ma_slow_buffer[1]))
    {
        strength += 0.30;
    }
    weight_sum += 0.30;
    
    // Bollinger Bands signal (weight: 0.20)
    double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
    if(current_price <= bb_lower[0] || current_price >= bb_upper[0])
        strength += 0.20;
    weight_sum += 0.20;
    
    // MACD signal (weight: 0.25)
    if((macd_main[0] > macd_signal[0] && macd_main[1] <= macd_signal[1]) ||
       (macd_main[0] < macd_signal[0] && macd_main[1] >= macd_signal[1]))
    {
        strength += 0.25;
    }
    weight_sum += 0.25;
    
    return strength / weight_sum;
}

//+------------------------------------------------------------------+
//| Get trade signal (-1: Sell, 0: No signal, 1: Buy)             |
//+------------------------------------------------------------------+
int GetTradeSignal()
{
    int buy_signals = 0;
    int sell_signals = 0;
    
    double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    // RSI signals
    if(rsi_buffer[0] < 30)
        buy_signals++;
    if(rsi_buffer[0] > 70)
        sell_signals++;
    
    // MA crossover signals
    if(ma_fast_buffer[0] > ma_slow_buffer[0] && ma_fast_buffer[1] <= ma_slow_buffer[1])
        buy_signals++;
    if(ma_fast_buffer[0] < ma_slow_buffer[0] && ma_fast_buffer[1] >= ma_slow_buffer[1])
        sell_signals++;
    
    // Bollinger Bands signals
    if(current_price <= bb_lower[0])
        buy_signals++;
    if(current_price >= bb_upper[0])
        sell_signals++;
    
    // MACD signals
    if(macd_main[0] > macd_signal[0] && macd_main[1] <= macd_signal[1])
        buy_signals++;
    if(macd_main[0] < macd_signal[0] && macd_main[1] >= macd_signal[1])
        sell_signals++;
    
    // Trend filter
    if(UseTrendFilter)
    {
        if(ma_fast_buffer[0] > ma_slow_buffer[0]) // Uptrend
            sell_signals = 0;
        else if(ma_fast_buffer[0] < ma_slow_buffer[0]) // Downtrend
            buy_signals = 0;
    }
    
    // Return strongest signal
    if(buy_signals > sell_signals && buy_signals >= 2)
        return 1;
    else if(sell_signals > buy_signals && sell_signals >= 2)
        return -1;
    
    return 0;
}

//+------------------------------------------------------------------+
//| Open a new trade                                                |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE order_type)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    
    double price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = 0, tp = 0;
    
    // Calculate stop loss and take profit
    if(order_type == ORDER_TYPE_BUY)
    {
        sl = price - StopLoss * _Point;
        tp = price + TakeProfit * _Point;
    }
    else
    {
        sl = price + StopLoss * _Point;
        tp = price - TakeProfit * _Point;
    }
    
    // Prepare trade request
    ZeroMemory(request);
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = LotSize;
    request.type = order_type;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = magic_number;
    request.comment = "EURUSD AI Bot";
    
    // Send trade request
    if(OrderSend(request, result))
    {
        Print("Trade opened successfully: ", EnumToString(order_type), " at ", price);
        last_trade_time = TimeCurrent();
    }
    else
    {
        Print("Error opening trade: ", result.retcode);
    }
}

//+------------------------------------------------------------------+
//| Count current trades                                            |
//+------------------------------------------------------------------+
int CountTrades()
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

//+------------------------------------------------------------------+
//| Manage existing trades                                          |
//+------------------------------------------------------------------+
void ManageTrades()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == magic_number)
            {
                // Add trailing stop or other management logic here
                // For now, let SL/TP handle the exits
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if it's trading time                                      |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    
    // Don't trade on weekends
    if(dt.day_of_week == 0 || dt.day_of_week == 6)
        return false;
    
    // Don't trade on Friday if disabled
    if(!TradeOnFriday && dt.day_of_week == 5)
        return false;
    
    // Check trading hours
    if(dt.hour < StartHour || dt.hour >= EndHour)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management                     |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * MaxRisk / 100.0;
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (StopLoss * tick_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = MathRound(lot_size / lot_step) * lot_step;
    
    return lot_size;
}