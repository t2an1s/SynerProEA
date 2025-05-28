    // SynPropEA2.mq5
    #property copyright "Your Name/Alias"
    #property link      "Your Link"
    #property version   "1.00"
    #property strict
    #property description "Slave EA for Synergy Strategy - Hedge Account"

    // --- Inputs ---
    input string InpMasterCommandFile       = "SynerProEA_Commands.csv"; // File to read commands from Master EA
    input string InpSlaveStatusFile         = "EA2_Status.txt";        // File to write this EA's status
    input int    InpMagicNumber_Slave       = 67890;                   // Magic number for trades placed by this EA
    input int    InpSlippage_Slave          = 5;                       // Slippage in points for trade execution
    input int    InpUpdateIntervalSeconds   = 5;                       // How often to check files and update status (seconds)
    input string InpMasterTicketCommentPrefix = "MSTR_TKT:";         // Prefix for master ticket in trade comment
    input bool   InpEnableTrading           = true;                    // Enable/disable trading actions by this EA

    // --- Hedge Lot Sizing Context Inputs (from Master EA's prop challenge perspective) ---
    input double InpChallengeCost_HedgeContext      = 700.0; // Example: Prop challenge cost
    input double InpMaxDrawdownProp_HedgeContext  = 4000.0; // Example: Max DD allowed on prop account
    input double InpSlipBufferPercent_HedgeContext= 10.0;   // Example: 10% for slippage buffer (0.10 in Pine)

    // --- Global Variables ---
    int    g_master_command_file_handle = INVALID_HANDLE;
    int    g_slave_status_file_handle   = INVALID_HANDLE;
    string g_csv_delimiter              = ","; // Must match SynPropEA1.mq5
    datetime g_last_processed_cmd_timestamp = 0;
    double g_slave_balance_at_day_start = 0.0;
    datetime g_last_day_for_daily_reset_slave = 0;

    // Mini Dashboard
    string g_mini_dash_prefix = "SynPropEASlave_Dash_";
    string g_ea_status_string = "Initializing...";
    string g_last_cmd_processed_str = "None";
    double g_point_value;
    int    g_digits_value;

    // Trade object
    #include <Trade\Trade.mqh>
    CTrade trade;

    //+------------------------------------------------------------------+
    //| Expert initialization function                                   |
    //+------------------------------------------------------------------+
    int OnInit()
    {
    g_point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    g_digits_value = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    trade.SetExpertMagicNumber(InpMagicNumber_Slave);
    trade.SetDeviationInPoints(InpSlippage_Slave);
    trade.SetTypeFillingBySymbol(_Symbol); // Or set specific filling type if needed

    MqlDateTime temp_dt;
    TimeToStruct(TimeCurrent(), temp_dt);
    temp_dt.hour = 0;
    temp_dt.min = 0;
    temp_dt.sec = 0;
    g_last_day_for_daily_reset_slave = StructToTime(temp_dt);
    g_slave_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE);

    Dashboard_Mini_Init();
    UpdateAndWriteSlaveStatusFile(true, "Initialized"); // Initial status write
    UpdateMiniDashboard();

    if(InpUpdateIntervalSeconds > 0)
        {
        EventSetTimer(InpUpdateIntervalSeconds);
        }
    else
        {
        Print("Update interval is 0, EA will only process on new ticks if not using timer.");
        }
        
    Print("File operations for inter-EA communication will use the common shared directory (FILE_COMMON).");
        
    PrintFormat("SynPropEA2 (Slave) Initialized. Version: %s. Master Command File: '%s', Slave Status File: '%s'",
                "1.00", InpMasterCommandFile, InpSlaveStatusFile);
    return(INIT_SUCCEEDED);
    }
    //+------------------------------------------------------------------+
    //| Expert deinitialization function                                 |
    //+------------------------------------------------------------------+
    void OnDeinit(const int reason)
    {
    if(InpUpdateIntervalSeconds > 0)
        {
        EventKillTimer();
        }
    Dashboard_Mini_Deinit();
    // Write a final "Deinitialized" status if possible
    // FileClose(g_master_command_file_handle); // Should be closed after each read
    // FileClose(g_slave_status_file_handle);   // Should be closed after each write
    Print("SynPropEA2 (Slave) Deinitialized. Reason: ", reason);
    }
    //+------------------------------------------------------------------+
    //| Expert tick function (if not using timer)                      |
    //+------------------------------------------------------------------+
    void OnTick()
    {
    if(InpUpdateIntervalSeconds <= 0) // Only run OnTick logic if timer is disabled
        {
        CheckForNewDay();
        ProcessMasterCommandFile();
        UpdateAndWriteSlaveStatusFile(true, g_ea_status_string); // Use current status
        UpdateMiniDashboard();
        }
    }
    //+------------------------------------------------------------------+
    //| Timer function                                                   |
    //+------------------------------------------------------------------+
    void OnTimer()
    {
    if(InpUpdateIntervalSeconds > 0) // Ensure this is only for timed events
        {
        CheckForNewDay();
        ProcessMasterCommandFile();
        UpdateAndWriteSlaveStatusFile(true, g_ea_status_string); // Use current status
        UpdateMiniDashboard();
        }
    }
    //+------------------------------------------------------------------+
    //| Check for a new trading day                                      |
    //+------------------------------------------------------------------+
    void CheckForNewDay()
    {
    MqlDateTime current_day_struct;
    TimeToStruct(TimeCurrent(), current_day_struct);
    current_day_struct.hour = 0;
    current_day_struct.min = 0;
    current_day_struct.sec = 0;
    datetime current_day_start = StructToTime(current_day_struct);

    if(current_day_start > g_last_day_for_daily_reset_slave)
        {
        g_slave_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE);
        g_last_day_for_daily_reset_slave = current_day_start;
        Print("SynPropEA2: New day detected. Daily PnL Balance Start for slave updated to: ", g_slave_balance_at_day_start);
        }
    }

    //+------------------------------------------------------------------+
    //| Process Master Command File                                      |
    //+------------------------------------------------------------------+
    void ProcessMasterCommandFile()
    {
    if(InpMasterCommandFile == "")
        {
        g_ea_status_string = "Cmd File N/A";
        return;
        }

    g_master_command_file_handle = FileOpen(InpMasterCommandFile, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
    if(g_master_command_file_handle == INVALID_HANDLE)
        {
        // Log error less frequently to avoid spamming
        static datetime last_error_log_time = 0;
        if(TimeCurrent() - last_error_log_time > 60)
        {
            PrintFormat("ProcessMasterCommandFile: Error opening command file '%s' (in shared folder). Error: %d", InpMasterCommandFile, GetLastError());
            last_error_log_time = TimeCurrent();
        }
        g_ea_status_string = "Cmd File Read Err";
        return;
        }

    string cmd_type, symbol_str, master_ticket_str, lots_str, entry_str, sl_str, tp_str, cmd_timestamp_str;
    datetime cmd_timestamp_dt;
    ulong master_ticket;
    double lots, sl, tp;

    // Read all lines and process new ones
    // File an array with all commands and then iterate to find unprocessed ones might be safer for complex scenarios
    // For now, simple sequential read and check timestamp
    
    // To avoid reprocessing, we must ensure we read from the beginning and find all *new* commands
    // A more robust approach might be for the master to write a unique command ID
    // For this version, we rely on the timestamp and process all commands since the last processed one.
    
    FileSeek(g_master_command_file_handle, 0, SEEK_SET); // Start from beginning

    while(!FileIsEnding(g_master_command_file_handle))
        {
        cmd_type = FileReadString(g_master_command_file_handle);
        master_ticket_str = FileReadString(g_master_command_file_handle); // Read master_ticket second
        
        // Read remaining fields, some might be placeholders depending on cmd_type
        symbol_str = FileReadString(g_master_command_file_handle);
        lots_str = FileReadString(g_master_command_file_handle);
        entry_str = FileReadString(g_master_command_file_handle); 
        sl_str = FileReadString(g_master_command_file_handle);
        tp_str = FileReadString(g_master_command_file_handle);
        cmd_timestamp_str = FileReadString(g_master_command_file_handle);
        PrintFormat("DEBUG EA2: Raw cmd_timestamp_str read: '%s'", cmd_timestamp_str); 

        if(!FileIsLineEnding(g_master_command_file_handle) && !FileIsEnding(g_master_command_file_handle))
            {
            Print("ProcessMasterCommandFile: Incomplete line read from command file. Skipping rest of file.");
            break; 
            }

        cmd_timestamp_dt = (long)StringToDouble(cmd_timestamp_str);
        PrintFormat("DEBUG EA2: Converted cmd_timestamp_dt: %s (long value: %d)", TimeToString(cmd_timestamp_dt), cmd_timestamp_dt); 

        if(cmd_timestamp_dt > g_last_processed_cmd_timestamp)
            {
            master_ticket = StringToInteger(master_ticket_str); // Assuming master_ticket fits in int, ulong is safer from file though.
                                                                // For consistency with ulong master_ticket var type, should be StringToULong if available or parse carefully.
                                                                // Let's stick to StringToInteger for now as it was used before, but flag for review.

            PrintFormat("ProcessMasterCommandFile: New Command Received - Type: %s, MasterTicket: %s (%d), Symbol: %s, CmdTime: %s",
                        cmd_type, master_ticket_str, master_ticket, symbol_str, TimeToString(cmd_timestamp_dt));
            g_last_cmd_processed_str = cmd_type + " @ " + TimeToString(cmd_timestamp_dt, TIME_SECONDS);

            if(InpEnableTrading)
            {
                if(cmd_type == "OPEN_LONG" || cmd_type == "OPEN_SHORT")
                {
                  // CRITICAL BUG FIX: Check if a slave trade for this master_ticket already exists
                  ulong existing_slave_ticket = FindSlavePositionByMasterTicket(master_ticket);
                  if(existing_slave_ticket > 0)
                    {
                      PrintFormat("ProcessMasterCommandFile: Slave trade for master ticket %d (slave ticket %d) already exists. Skipping duplicate OPEN command.", 
                                  master_ticket, existing_slave_ticket);
                      g_ea_status_string = "Dup OPEN Skip";
                    }
                  else
                    {
                      lots = StringToDouble(lots_str);
                      // sl and tp are master's SL/TP, used to derive slave's SL/TP
                      double master_sl_from_file = StringToDouble(sl_str);
                      double master_tp_from_file = StringToDouble(tp_str);
                      ExecuteHedgeTrade(cmd_type, symbol_str, lots, master_tp_from_file, master_sl_from_file, master_ticket);
                    }
                }
                else if(cmd_type == "CLOSE_HEDGE")
                {
                ulong slave_ticket_to_close = FindSlavePositionByMasterTicket(master_ticket);
                if(slave_ticket_to_close > 0)
                    {
                    bool close_res = trade.PositionClose(slave_ticket_to_close);
                    if(close_res) 
                        {
                        PrintFormat("ProcessMasterCommandFile: CLOSE_HEDGE command successful for master ticket %d (slave ticket %d).", master_ticket, slave_ticket_to_close);
                        g_ea_status_string = "Hedge Closed";
                        }
                    else 
                        {
                        PrintFormat("ProcessMasterCommandFile: Failed to close slave ticket %d (master %d). Error: %d, Retcode: %d", 
                                    slave_ticket_to_close, master_ticket, GetLastError(), trade.ResultRetcode());
                        g_ea_status_string = "Hedge Close Fail";
                        }
                    }
                else
                    {
                    PrintFormat("ProcessMasterCommandFile: CLOSE_HEDGE command for master ticket %d - no corresponding slave position found.", master_ticket);
                    g_ea_status_string = "Close: Slave N/F";
                    }
                }
                else if(cmd_type == "MODIFY_HEDGE")
                {
                double new_slave_sl = StringToDouble(sl_str); // This sl_str from file is Master EA's new TP
                double new_slave_tp = StringToDouble(tp_str); // This tp_str from file is Master EA's new SL
                
                ulong slave_ticket_to_modify = FindSlavePositionByMasterTicket(master_ticket);
                if(slave_ticket_to_modify > 0)
                    {
                    PrintFormat("ProcessMasterCommandFile: Attempting MODIFY_HEDGE for master ticket %d (slave ticket %d). New Slave SL: %.5f, New Slave TP: %.5f", 
                                master_ticket, slave_ticket_to_modify, new_slave_sl, new_slave_tp);
                    bool modify_res = trade.PositionModify(slave_ticket_to_modify, new_slave_sl, new_slave_tp);
                    if(modify_res)
                        {
                        PrintFormat("ProcessMasterCommandFile: MODIFY_HEDGE successful for slave ticket %d.", slave_ticket_to_modify);
                        g_ea_status_string = "Hedge SL/TP ModOK";
                        }
                    else
                        {
                        PrintFormat("ProcessMasterCommandFile: Failed to MODIFY_HEDGE for slave ticket %d. Error: %d, Retcode: %d", 
                                    slave_ticket_to_modify, GetLastError(), trade.ResultRetcode());
                        g_ea_status_string = "Hedge SL/TP ModFail";
                        }
                    }
                else
                    {
                    PrintFormat("ProcessMasterCommandFile: MODIFY_HEDGE command for master ticket %d - no corresponding slave position found.", master_ticket);
                    g_ea_status_string = "Modify: Slave N/F";
                    }
                }
            }
            else {
                Print("ProcessMasterCommandFile: Trading disabled. Command not executed.");
                g_ea_status_string = "Trading Disabled";
            }
            g_last_processed_cmd_timestamp = cmd_timestamp_dt; 
            }
        else
            {
            PrintFormat("DEBUG EA2: Command skipped. cmd_timestamp_dt (%d / %s) not > g_last_processed_cmd_timestamp (%d / %s). For MasterTicketStr: %s",
                        cmd_timestamp_dt, TimeToString(cmd_timestamp_dt),
                        g_last_processed_cmd_timestamp, TimeToString(g_last_processed_cmd_timestamp),
                        master_ticket_str); // DEBUG
            }
        }
    FileClose(g_master_command_file_handle);
    g_master_command_file_handle = INVALID_HANDLE; // Reset handle
    }

    //+------------------------------------------------------------------+
    //| Calculate Slave Lot Size based on Hedge Factor                   |
    //+------------------------------------------------------------------+
    double CalculateSlaveLotSize(double master_lots, string for_symbol)
    {
        if(InpMaxDrawdownProp_HedgeContext <= 0)
        {
            PrintFormat("CalculateSlaveLotSize: InpMaxDrawdownProp_HedgeContext (%.2f) is zero or negative. Cannot calculate hedge factor. Defaulting to master lots.", 
                        InpMaxDrawdownProp_HedgeContext);
            return master_lots; // Or a minimal lot, or zero if preferred for safety
        }

        double slip_buffer_decimal = InpSlipBufferPercent_HedgeContext / 100.0;
        double challenge_cost_with_buffer = InpChallengeCost_HedgeContext * (1.0 + slip_buffer_decimal);
        
        double hedge_factor = MathMin(1.0, challenge_cost_with_buffer / InpMaxDrawdownProp_HedgeContext);
        PrintFormat("CalculateSlaveLotSize: MasterLots=%.2f, ChallengeCost=%.2f, SlipBufferPct=%.2f%%, MaxDDProp=%.2f -> HedgeFactor=%.4f",
                    master_lots, InpChallengeCost_HedgeContext, InpSlipBufferPercent_HedgeContext, InpMaxDrawdownProp_HedgeContext, hedge_factor);

        double raw_slave_lot = master_lots * hedge_factor;
        
        // Normalize the lot size
        double min_lot = SymbolInfoDouble(for_symbol, SYMBOL_VOLUME_MIN);
        double max_lot = SymbolInfoDouble(for_symbol, SYMBOL_VOLUME_MAX);
        double lot_step = SymbolInfoDouble(for_symbol, SYMBOL_VOLUME_STEP);

        if(min_lot == 0 && lot_step == 0) // Edge case, avoid division by zero if symbol info is weird
        {
            PrintFormat("CalculateSlaveLotSize: MinLot and LotStep are zero for symbol %s. Returning raw calculated lot %.5f", for_symbol, raw_slave_lot);
            return raw_slave_lot > 0 ? raw_slave_lot : 0.01; // Fallback to something small or raw
        }
        if(lot_step == 0 && min_lot > 0) lot_step = min_lot; // if lot_step is 0 but min_lot isn't, use min_lot as step
        if(lot_step == 0 && min_lot == 0) lot_step = 0.01; // Absolute fallback if symbol info is unhelpful
        
        double normalized_lot = master_lots; // Default to master_lots if calculations go awry before this point
        if (raw_slave_lot > 0 && lot_step > 0)
        {
            normalized_lot = MathRound(raw_slave_lot / lot_step) * lot_step;
        }
        else if (raw_slave_lot > 0) // lot_step might be zero, but raw_slave_lot is what we want
        {
            normalized_lot = raw_slave_lot;
        }
        else // raw_slave_lot is zero or negative, implies hedge_factor was zero or negative, or master_lots was zero
        {
            normalized_lot = 0.0;
        }

        normalized_lot = MathMax(normalized_lot, min_lot); // Ensure at least min lot
        normalized_lot = MathMin(normalized_lot, max_lot); // Ensure not over max lot
        
        // If after all calculations, the lot is effectively zero (e.g. due to very small master_lots * hedge_factor, then rounded down by lot_step)
        // and min_lot is also zero (e.g. for some CFDs/Indices), we should ensure it's at least *some* tradeable volume if master_lots was > 0.
        // However, if master_lots was 0, or hedge_factor was 0, then 0 is correct.
        if (normalized_lot == 0 && master_lots > 0 && hedge_factor > 0 && min_lot == 0 && lot_step > 0) {
            normalized_lot = lot_step; // Smallest possible tradeable unit if it was rounded to zero but shouldn't be.
        }
        else if (normalized_lot == 0 && master_lots > 0 && hedge_factor > 0 && min_lot > 0) {
            normalized_lot = min_lot; // ensure it's at least min_lot if it was rounded to zero
        }

        PrintFormat("CalculateSlaveLotSize: RawSlaveLot=%.5f, NormalizedLot=%.2f (Min:%.2f, Max:%.2f, Step:%.2f for %s)",
                    raw_slave_lot, normalized_lot, min_lot, max_lot, lot_step, for_symbol);
                
        return normalized_lot;
    }

    //+------------------------------------------------------------------+
    //| Execute Hedge Trade                                              |
    //+------------------------------------------------------------------+
    bool ExecuteHedgeTrade(string master_cmd_type, string symbol, double master_lots_received, double hedge_sl_price, double hedge_tp_price, ulong master_ticket)
    {
        if(symbol != _Symbol)
        {
            PrintFormat("ExecuteHedgeTrade: Command symbol %s does not match chart symbol %s. No trade.", symbol, _Symbol);
            g_ea_status_string = "Symbol Mismatch";
            return false;
        }

        ENUM_ORDER_TYPE slave_order_type;
        if(master_cmd_type == "OPEN_LONG")
        {
            slave_order_type = ORDER_TYPE_SELL; // Hedge for master's long is a short
        }
        else if(master_cmd_type == "OPEN_SHORT")
        {
            slave_order_type = ORDER_TYPE_BUY;  // Hedge for master's short is a long
        }
        else
        {
            Print("ExecuteHedgeTrade: Unknown master command type: ", master_cmd_type);
            g_ea_status_string = "Unknown Cmd Type";
            return false;
        }

        // Calculate slave lot size based on the received master_lots and hedge factor logic
        double calculated_slave_lots = CalculateSlaveLotSize(master_lots_received, symbol);

        if(calculated_slave_lots <= 0) // Or less than SYMBOL_VOLUME_MIN, depending on strictness
        {
            PrintFormat("ExecuteHedgeTrade: Calculated slave lot size is %.2f. No trade will be placed for master ticket %d.", calculated_slave_lots, master_ticket);
            g_ea_status_string = "Slave Lot Zero";
            return false; // Do not proceed with zero or invalid lot size
        }

        string comment = InpMasterTicketCommentPrefix + IntegerToString(master_ticket);
        bool result = false;

        if(slave_order_type == ORDER_TYPE_BUY)
        {
            result = trade.Buy(calculated_slave_lots, symbol, 0, hedge_sl_price, hedge_tp_price, comment);
        }
        else if(slave_order_type == ORDER_TYPE_SELL)
        {
            result = trade.Sell(calculated_slave_lots, symbol, 0, hedge_sl_price, hedge_tp_price, comment);
        }

        if(result)
        {
            PrintFormat("ExecuteHedgeTrade: %s executed for %.2f lots (master lots %.2f) on %s. MasterTicket: %d. ReqSL: %.5f, ReqTP: %.5f. SlaveTicket: %d",
                        EnumToString(slave_order_type), calculated_slave_lots, master_lots_received, symbol, master_ticket, hedge_sl_price, hedge_tp_price, trade.ResultOrder());
            g_ea_status_string = EnumToString(slave_order_type) + " Sent (" + DoubleToString(calculated_slave_lots,2) + "L)";
        }
        else
        {
            PrintFormat("ExecuteHedgeTrade: Failed to execute %s for %.2f lots (master lots %.2f) on %s. MasterTicket: %d. Error: %d, Retcode: %d",
                        EnumToString(slave_order_type), calculated_slave_lots, master_lots_received, symbol, master_ticket, GetLastError(), trade.ResultRetcode());
            g_ea_status_string = "Trade Exec Failed";
        }
        return result;
    }

    //+------------------------------------------------------------------+
    //| Find Slave Position by Master Ticket in Comment                  |
    //+------------------------------------------------------------------+
    ulong FindSlavePositionByMasterTicket(ulong master_ticket_to_find)
    {
        string search_comment = InpMasterTicketCommentPrefix + IntegerToString(master_ticket_to_find);
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong pos_ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(pos_ticket))
            {
                if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber_Slave &&
                    PositionGetString(POSITION_SYMBOL) == _Symbol &&
                    PositionGetString(POSITION_COMMENT) == search_comment)
                {
                    return pos_ticket; // Found
                }
            }
        }
        return 0; // Not found
    }

    //+------------------------------------------------------------------+
    //| Update and Write Slave Status File                               |
    //+------------------------------------------------------------------+
    void UpdateAndWriteSlaveStatusFile(bool is_connected_override, string status_text_override)
    {
        if(InpSlaveStatusFile == "") return;

        g_slave_status_file_handle = FileOpen(InpSlaveStatusFile, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
        if(g_slave_status_file_handle == INVALID_HANDLE)
        {
            PrintFormat("UpdateAndWriteSlaveStatusFile: Error opening status file '%s' (in shared folder) for writing. Error: %d", InpSlaveStatusFile, GetLastError());
            g_ea_status_string = "Status File Write Err"; // Update internal status
            return;
        }

        double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double daily_pnl = current_equity - g_slave_balance_at_day_start;
        long acc_num = AccountInfoInteger(ACCOUNT_LOGIN);
        string acc_curr = AccountInfoString(ACCOUNT_CURRENCY);
        string is_connected_str = is_connected_override ? "true" : "false";
        datetime current_timestamp = TimeCurrent();
        
        // Get current open volume for slave EA trades
        double current_open_volume = 0;
        for(int i = PositionsTotal() - 1; i >= 0; i--)
          {
            ulong pos_ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(pos_ticket))
              {
                if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber_Slave && PositionGetString(POSITION_SYMBOL) == _Symbol)
                  {
                    current_open_volume += PositionGetDouble(POSITION_VOLUME);
                  }
              }
          }
          
        PrintFormat("Slave Status Write: Calculated current_open_volume: %.2f", current_open_volume); // DEBUG VOLUME
      
        int leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
        PrintFormat("Slave Status Write: Account Leverage from slave: %d", leverage); // DEBUG LEVERAGE

        string server = AccountInfoString(ACCOUNT_SERVER);
        PrintFormat("Slave Status Write: Account Server from slave: '%s'", server); // DEBUG SERVER

        // Format: Balance,Equity,DailyPnL,AccountNumber,AccountCurrency,StatusText,IsConnected(true/false),FileTimestamp(long),OpenVolume,Leverage,Server
        FileWrite(g_slave_status_file_handle, DoubleToString(current_balance, 2));
        FileWrite(g_slave_status_file_handle, DoubleToString(current_equity, 2));
        FileWrite(g_slave_status_file_handle, DoubleToString(daily_pnl, 2));
        FileWrite(g_slave_status_file_handle, IntegerToString(acc_num));
        FileWrite(g_slave_status_file_handle, acc_curr);
        FileWrite(g_slave_status_file_handle, status_text_override); // Use the provided status
        FileWrite(g_slave_status_file_handle, is_connected_str);
        FileWrite(g_slave_status_file_handle, IntegerToString(current_timestamp));
        FileWrite(g_slave_status_file_handle, DoubleToString(current_open_volume, 2)); // Added Open Volume
        FileWrite(g_slave_status_file_handle, IntegerToString(leverage));           // Added Leverage
        FileWrite(g_slave_status_file_handle, server);                              // Added Server

        FileClose(g_slave_status_file_handle);
        g_slave_status_file_handle = INVALID_HANDLE; // Reset handle
        
        // Update internal status if it wasn't an error status already set
        if(g_ea_status_string != "Status File Write Err")
        {
            g_ea_status_string = status_text_override;
        }
    }

    //+------------------------------------------------------------------+
    //| Mini Dashboard Functions                                         |
    //+------------------------------------------------------------------+
    void CreateMiniDashText(long chart_id, string name, string text, int x, int y, color clr, int font_size=8, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
    {
        ObjectDelete(chart_id, name);
        if(ObjectCreate(chart_id, name, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
            ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x);
            ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
            ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clr);
            ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, font_size);
            ObjectSetString(chart_id, name, OBJPROP_FONT, "Arial");
            ObjectSetInteger(chart_id, name, OBJPROP_ANCHOR, anchor);
            ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
        }
    }

    void Dashboard_Mini_Init()
    {
        long chartID = ChartID();
        int y_start = 10;
        int y_step = 15;
        int x_pos = 10;

        CreateMiniDashText(chartID, g_mini_dash_prefix + "Title", "SynPropEA2 Slave v" + "1.00", x_pos, y_start, clrGray);
        y_start += y_step;
        CreateMiniDashText(chartID, g_mini_dash_prefix + "StatusLabel", "Status:", x_pos, y_start, clrGray);
        CreateMiniDashText(chartID, g_mini_dash_prefix + "StatusValue", "Initializing...", x_pos + 60, y_start, clrBlack);
        y_start += y_step;
        CreateMiniDashText(chartID, g_mini_dash_prefix + "LastCmdLabel", "Last Cmd:", x_pos, y_start, clrGray);
        CreateMiniDashText(chartID, g_mini_dash_prefix + "LastCmdValue", "None", x_pos + 60, y_start, clrBlack);
        y_start += y_step;
        CreateMiniDashText(chartID, g_mini_dash_prefix + "DailyPnLLabel", "Daily PnL:", x_pos, y_start, clrGray);
        CreateMiniDashText(chartID, g_mini_dash_prefix + "DailyPnLValue", "0.00", x_pos + 60, y_start, clrDodgerBlue);
        y_start += y_step;
        CreateMiniDashText(chartID, g_mini_dash_prefix + "BalLabel", "Balance:", x_pos, y_start, clrGray);
        CreateMiniDashText(chartID, g_mini_dash_prefix + "BalValue", "0.00", x_pos + 60, y_start, clrBlack);
        y_start += y_step;
        CreateMiniDashText(chartID, g_mini_dash_prefix + "EqLabel", "Equity:", x_pos, y_start, clrGray);
        CreateMiniDashText(chartID, g_mini_dash_prefix + "EqValue", "0.00", x_pos + 60, y_start, clrBlack);
        ChartRedraw(chartID);
    }

    void UpdateMiniDashboard()
    {
        long chartID = ChartID();
        ObjectSetString(chartID, g_mini_dash_prefix + "StatusValue", OBJPROP_TEXT, g_ea_status_string);
        ObjectSetString(chartID, g_mini_dash_prefix + "LastCmdValue", OBJPROP_TEXT, g_last_cmd_processed_str);
        
        double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double daily_pnl = current_equity - g_slave_balance_at_day_start;

        ObjectSetString(chartID, g_mini_dash_prefix + "DailyPnLValue", OBJPROP_TEXT, DoubleToString(daily_pnl, 2));
        ObjectSetInteger(chartID, g_mini_dash_prefix + "DailyPnLValue", OBJPROP_COLOR, (daily_pnl >=0 ? clrForestGreen : clrFireBrick));
        ObjectSetString(chartID, g_mini_dash_prefix + "BalValue", OBJPROP_TEXT, DoubleToString(current_balance, 2));
        ObjectSetString(chartID, g_mini_dash_prefix + "EqValue", OBJPROP_TEXT, DoubleToString(current_equity, 2));
        ChartRedraw(chartID);
    }

    void Dashboard_Mini_Deinit()
    {
        ObjectsDeleteAll(ChartID(), g_mini_dash_prefix);
        ChartRedraw(ChartID());
    }
    //+------------------------------------------------------------------+ 
