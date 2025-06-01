    // SynPropEA2.mq5
    #property copyright "t2an1s"
    #property link      "https://github.com/t2an1s/SynerProEA"
    #property version   "1.04" // Updated with enhanced position linkage system
    #property strict
    #property description "Slave EA for Synergy Strategy - Enhanced Hedge Account with Position Linkage"

    // --- Inputs ---
    input string InpMasterCommandFile       = "SynerProEA_Commands.csv"; // File to read commands from Master EA
    input string InpSlaveStatusFile         = "EA2_Status.txt";        // File to write this EA's status
    input int    InpMagicNumber_Slave       = 67890;                   // Magic number for trades placed by this EA
    input int    InpSlippage_Slave          = 5;                       // Slippage in points for trade execution
    input int    InpUpdateIntervalSeconds   = 5;                       // How often to check files and update status (seconds)
    input string InpMasterTicketCommentPrefix = "MSTR_TKT:";         // Prefix for master ticket in trade comment
    input bool   InpEnableTrading           = true;                    // Enable/disable trading actions by this EA
    input bool   InpNotifyMasterOnClose    = true;                    // Notify master EA when hedge positions close
    input int    InpMaxCommandAgeSeconds   = 3600;                   // Maximum age of commands to process (seconds)

    // --- Hedge Lot Sizing Context Inputs (from Master EA's prop challenge perspective) ---
    input double InpChallengeCost_HedgeContext      = 700.0; // Example: Prop challenge cost
    input double InpMaxDrawdownProp_HedgeContext  = 4000.0; // Example: Max DD allowed on prop account
    input double InpSlipBufferPercent_HedgeContext= 10.0;   // Example: 10% for slippage buffer (0.10 in Pine)

    // --- Global Variables ---
    int    g_master_command_file_handle = INVALID_HANDLE;
    int    g_slave_status_file_handle   = INVALID_HANDLE;
    string g_csv_delimiter              = ","; // Must match SynPropEA1.mq5
    datetime g_last_processed_cmd_timestamp = 0;
    string g_last_processed_cmd_signature = ""; // Track command signature for better duplicate detection
    int    g_last_processed_cmd_sequence = 0;   // Track command sequence number
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

    // Initialize command tracking - Reset on startup to ensure fresh start
    g_last_processed_cmd_timestamp = 0;
    g_last_processed_cmd_signature = "";
    g_last_processed_cmd_sequence = 0;
    
    PrintFormat("OnInit: Command tracking initialized. Timestamp: %s, Sequence: %d", 
               TimeToString(g_last_processed_cmd_timestamp), g_last_processed_cmd_sequence);

    Dashboard_Mini_Init();
    UpdateAndWriteSlaveStatusFile(true, "Initialized"); // Initial status write
    
    // Check for orphaned hedge positions on startup
    CheckForOrphanedHedgePositions();
    
    UpdateMiniDashboard();

    if(InpUpdateIntervalSeconds > 0)
        {
        EventSetTimer(InpUpdateIntervalSeconds);
        PrintFormat("OnInit: Timer set to %d seconds for periodic updates.", InpUpdateIntervalSeconds);
        }
    else
        {
        Print("OnInit: Update interval is 0, EA will only process on new ticks if not using timer.");
        }
        
    PrintFormat("SynPropEA2 (Slave) Initialized. Version: %s. Master Command File: '%s', Slave Status File: '%s'",
                "1.04", InpMasterCommandFile, InpSlaveStatusFile);
    PrintFormat("OnInit: Magic Number: %d, Max Command Age: %d seconds, Trading Enabled: %s", 
               InpMagicNumber_Slave, InpMaxCommandAgeSeconds, InpEnableTrading ? "Yes" : "No");
                
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
    //| Trade Event Function                                             |
    //+------------------------------------------------------------------+
    void OnTradeTransaction(const MqlTradeTransaction& trans,
                            const MqlTradeRequest& request,
                            const MqlTradeResult& result)
      {
       // Focus on position closures of our hedge trades
       if(trans.type == TRADE_TRANSACTION_POSITION && trans.position > 0)
         {
          // Check if position was closed (PositionSelectByTicket will return false)
          if(!PositionSelectByTicket(trans.position))
            {
             // Position was closed, check if it was one of our hedge positions
             // We need to check historical trades to determine if this was our trade
             // For now, we'll use a simpler approach and rely on periodic cleanup
             PrintFormat("OnTradeTransaction: Position #%d was closed. EA2 does not currently implement master notification on hedge closure.", trans.position);
            }
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
    //| Process Master Command File (Enhanced with Better Error Handling)|
    //+------------------------------------------------------------------+
    void ProcessMasterCommandFile()
    {
        if(InpMasterCommandFile == "")
            {
            g_ea_status_string = "Cmd File N/A";
            return;
            }

        // Enhanced file reading with retry mechanism for better reliability
        int max_read_retries = 3;
        int retry_delay_ms = 50;
        bool file_read_successfully = false;
        
        for(int attempt = 1; attempt <= max_read_retries && !file_read_successfully; attempt++)
        {
            g_master_command_file_handle = FileOpen(InpMasterCommandFile, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
            if(g_master_command_file_handle == INVALID_HANDLE)
                {
                if(attempt == max_read_retries)
                {
                    // Log error less frequently to avoid spamming
                    static datetime last_error_log_time = 0;
                    if(TimeCurrent() - last_error_log_time > 60)
                    {
                        PrintFormat("ProcessMasterCommandFile: Error opening command file '%s' after %d attempts. Error: %d", 
                                   InpMasterCommandFile, max_read_retries, GetLastError());
                        last_error_log_time = TimeCurrent();
                    }
                    g_ea_status_string = "Cmd File Read Err";
                }
                else
                {
                    Sleep(retry_delay_ms);
                }
                continue;
                }

            string cmd_type, symbol_str, master_ticket_str, lots_str, entry_str, sl_str, tp_str, cmd_timestamp_str, cmd_sequence_str;
            datetime cmd_timestamp_dt;
            ulong master_ticket;
            double lots, sl, tp;
            int cmd_sequence = 0;

            // Start from beginning of file
            FileSeek(g_master_command_file_handle, 0, SEEK_SET);

            // Read the command from the file
            if(!FileIsEnding(g_master_command_file_handle))
                {
                cmd_type = FileReadString(g_master_command_file_handle);
                master_ticket_str = FileReadString(g_master_command_file_handle);
                
                // Read remaining fields
                symbol_str = FileReadString(g_master_command_file_handle);
                lots_str = FileReadString(g_master_command_file_handle);
                entry_str = FileReadString(g_master_command_file_handle); 
                sl_str = FileReadString(g_master_command_file_handle);
                tp_str = FileReadString(g_master_command_file_handle);
                cmd_timestamp_str = FileReadString(g_master_command_file_handle);
                
                // Read new sequence number field if available
                if(!FileIsLineEnding(g_master_command_file_handle) && !FileIsEnding(g_master_command_file_handle))
                {
                    cmd_sequence_str = FileReadString(g_master_command_file_handle);
                    cmd_sequence = (int)StringToInteger(cmd_sequence_str);
                    PrintFormat("DEBUG EA2: Successfully read sequence number: %s -> %d", cmd_sequence_str, cmd_sequence);
                }
                else
                {
                    PrintFormat("DEBUG EA2: No sequence number found in command file (old format)");
                    cmd_sequence = 0;
                }

                PrintFormat("DEBUG EA2: Raw cmd_timestamp_str read: '%s', sequence: %d", cmd_timestamp_str, cmd_sequence); 

                if(cmd_type == "" || master_ticket_str == "")
                    {
                    Print("ProcessMasterCommandFile: Incomplete or invalid command data. Skipping.");
                    FileClose(g_master_command_file_handle);
                    g_master_command_file_handle = INVALID_HANDLE;
                    return;
                    }

                // Parse timestamp (handle both old and new formats)
                if(StringFind(cmd_timestamp_str, ".") >= 0)
                {
                    // New format with microsecond precision
                    string timestamp_parts[];
                    int parts_count = StringSplit(cmd_timestamp_str, '.', timestamp_parts);
                    if(parts_count >= 1)
                    {
                        cmd_timestamp_dt = (long)StringToDouble(timestamp_parts[0]);
                    }
                    else
                    {
                        cmd_timestamp_dt = (long)StringToDouble(cmd_timestamp_str);
                    }
                }
                else
                {
                    // Old format
                    cmd_timestamp_dt = (long)StringToDouble(cmd_timestamp_str);
                }

                PrintFormat("DEBUG EA2: Converted cmd_timestamp_dt: %s, sequence: %d", TimeToString(cmd_timestamp_dt), cmd_sequence); 

                // Enhanced duplicate detection using sequence number (primary) and timestamp + signature (fallback)
                bool is_duplicate = false;
                
                if(cmd_sequence > 0)
                {
                    // Use sequence number for duplicate detection (most reliable)
                    is_duplicate = (cmd_sequence <= g_last_processed_cmd_sequence);
                    PrintFormat("DEBUG EA2: Sequence-based duplicate check: current=%d, last=%d, is_duplicate=%s", 
                               cmd_sequence, g_last_processed_cmd_sequence, is_duplicate ? "true" : "false");
                }
                else
                {
                    // Fallback to timestamp and signature method for backward compatibility
                    string cmd_signature = cmd_type + "_" + master_ticket_str + "_" + cmd_timestamp_str;
                    is_duplicate = (cmd_timestamp_dt <= g_last_processed_cmd_timestamp && cmd_signature == g_last_processed_cmd_signature);
                    PrintFormat("DEBUG EA2: Timestamp-based duplicate check: signature=%s, is_duplicate=%s", 
                               cmd_signature, is_duplicate ? "true" : "false");
                }
                
                if(!is_duplicate && cmd_timestamp_dt > 0) // Valid timestamp
                    {
                    // Check command age to avoid processing very old commands
                    datetime current_time = TimeCurrent();
                    int command_age_seconds = (int)(current_time - cmd_timestamp_dt);
                    
                    if(InpMaxCommandAgeSeconds > 0 && command_age_seconds > InpMaxCommandAgeSeconds)
                      {
                       PrintFormat("ProcessMasterCommandFile: Skipping old command (age: %d seconds, max: %d). Type: %s, MasterTicket: %s", 
                                  command_age_seconds, InpMaxCommandAgeSeconds, cmd_type, master_ticket_str);
                       
                       // Update tracking even for skipped old commands to prevent re-processing
                       g_last_processed_cmd_timestamp = cmd_timestamp_dt; 
                       if(cmd_sequence > 0) g_last_processed_cmd_sequence = cmd_sequence;
                       g_last_processed_cmd_signature = cmd_type + "_" + master_ticket_str + "_" + cmd_timestamp_str;
                       
                       FileClose(g_master_command_file_handle);
                       g_master_command_file_handle = INVALID_HANDLE;
                       return;
                      }
                    
                    master_ticket = (ulong)StringToDouble(master_ticket_str);

                    PrintFormat("ProcessMasterCommandFile: New Command Received - Type: %s, MasterTicket: %s (%d), Symbol: %s, CmdTime: %s, Sequence: %d",
                                cmd_type, master_ticket_str, master_ticket, symbol_str, TimeToString(cmd_timestamp_dt), cmd_sequence);
                    g_last_cmd_processed_str = cmd_type + " @ " + TimeToString(cmd_timestamp_dt, TIME_SECONDS);

                    if(InpEnableTrading)
                    {
                        // Process command based on type
                        bool command_processed_successfully = ProcessCommand(cmd_type, master_ticket, symbol_str, lots_str, sl_str, tp_str);
                        
                        if(command_processed_successfully)
                        {
                            // Update processed command tracking only on successful processing
                            g_last_processed_cmd_timestamp = cmd_timestamp_dt;
                            if(cmd_sequence > 0) g_last_processed_cmd_sequence = cmd_sequence;
                            g_last_processed_cmd_signature = cmd_type + "_" + master_ticket_str + "_" + cmd_timestamp_str;
                            
                            PrintFormat("ProcessMasterCommandFile: Command processed successfully. Updated tracking: timestamp=%s, sequence=%d", 
                                       TimeToString(cmd_timestamp_dt), cmd_sequence);
                        }
                        else
                        {
                            PrintFormat("ProcessMasterCommandFile: Command processing failed for %s, master ticket %d", cmd_type, master_ticket);
                        }
                    }
                    else 
                    {
                        Print("ProcessMasterCommandFile: Trading disabled. Command not executed.");
                        g_ea_status_string = "Trading Disabled";
                    }
                    
                    file_read_successfully = true;
                    }
                else
                    {
                    if(is_duplicate)
                      {
                       PrintFormat("DEBUG EA2: Duplicate command detected. Type: %s, Sequence: %d (last: %d), skipping.", 
                                  cmd_type, cmd_sequence, g_last_processed_cmd_sequence);
                       g_ea_status_string = "Dup Cmd Skip";
                      }
                    else
                      {
                       PrintFormat("DEBUG EA2: Command skipped - invalid timestamp or other issue. cmd_timestamp_dt: %d", cmd_timestamp_dt);
                      }
                    file_read_successfully = true; // Don't retry for duplicate/invalid commands
                    }
                }
            else
                {
                PrintFormat("ProcessMasterCommandFile: Command file is empty or unreadable (attempt %d/%d).", attempt, max_read_retries);
                if(attempt == max_read_retries)
                {
                    g_ea_status_string = "Cmd File Empty";
                }
                file_read_successfully = true; // Don't retry for empty files
                }
                
            FileClose(g_master_command_file_handle);
            g_master_command_file_handle = INVALID_HANDLE;
            
            if(!file_read_successfully && attempt < max_read_retries)
            {
                Sleep(retry_delay_ms);
            }
        }
    }

    //+------------------------------------------------------------------+
    //| Process Individual Command (Separated for better organization)   |
    //+------------------------------------------------------------------+
    bool ProcessCommand(string cmd_type, ulong master_ticket, string symbol_str, string lots_str, string sl_str, string tp_str)
    {
        if(cmd_type == "OPEN_LONG" || cmd_type == "OPEN_SHORT")
        {
            // Enhanced duplicate check: Look for existing slave position
            ulong existing_slave_ticket = FindSlavePositionByMasterTicket(master_ticket);
            if(existing_slave_ticket > 0)
            {
                PrintFormat("ProcessCommand: Slave trade for master ticket %d (slave ticket %d) already exists. Skipping duplicate OPEN command.", 
                            master_ticket, existing_slave_ticket);
                g_ea_status_string = "Dup OPEN Skip";
                return true; // Consider this successful to avoid re-processing
            }
            
            double lots = StringToDouble(lots_str);
            double master_sl_from_file = StringToDouble(sl_str);
            double master_tp_from_file = StringToDouble(tp_str);
            
            PrintFormat("ProcessCommand: Executing hedge trade for master ticket %d. Master SL: %.5f, Master TP: %.5f", 
                        master_ticket, master_sl_from_file, master_tp_from_file);
            
            bool hedge_success = ExecuteHedgeTrade(cmd_type, symbol_str, lots, master_tp_from_file, master_sl_from_file, master_ticket);
            if(hedge_success)
            {
                PrintFormat("ProcessCommand: Hedge trade executed successfully for master ticket %d", master_ticket);
                g_ea_status_string = "Hedge Opened";
            }
            else
            {
                PrintFormat("ProcessCommand: Failed to execute hedge trade for master ticket %d", master_ticket);
                g_ea_status_string = "Hedge Open Fail";
            }
            return hedge_success;
        }
        else if(cmd_type == "CLOSE_HEDGE")
        {
            PrintFormat("ProcessCommand: Received CLOSE_HEDGE command for master ticket %d", master_ticket);
            ulong slave_ticket_to_close = FindSlavePositionByMasterTicket(master_ticket);
            if(slave_ticket_to_close > 0)
            {
                PrintFormat("ProcessCommand: Found slave position #%d for master ticket %d. Attempting to close...", slave_ticket_to_close, master_ticket);
                bool close_res = trade.PositionClose(slave_ticket_to_close);
                if(close_res) 
                {
                    PrintFormat("ProcessCommand: CLOSE_HEDGE command successful for master ticket %d (slave ticket %d).", master_ticket, slave_ticket_to_close);
                    g_ea_status_string = "Hedge Closed";
                    return true;
                }
                else 
                {
                    PrintFormat("ProcessCommand: Failed to close slave ticket %d (master %d). Error: %d, Retcode: %d, Comment: %s", 
                                slave_ticket_to_close, master_ticket, GetLastError(), trade.ResultRetcode(), trade.ResultComment());
                    g_ea_status_string = "Hedge Close Fail";
                    return false;
                }
            }
            else
            {
                PrintFormat("ProcessCommand: CLOSE_HEDGE command for master ticket %d - no corresponding slave position found. This may be normal if position was already closed.", master_ticket);
                g_ea_status_string = "Close: Slave N/F";
                return true; // Consider successful since position might already be closed
            }
        }
        else if(cmd_type == "MODIFY_HEDGE")
        {
            PrintFormat("ProcessCommand: Received MODIFY_HEDGE command for master ticket %d", master_ticket);
            double new_slave_sl = NormalizeDouble(StringToDouble(sl_str), g_digits_value);
            double new_slave_tp = NormalizeDouble(StringToDouble(tp_str), g_digits_value);
            
            ulong slave_ticket_to_modify = FindSlavePositionByMasterTicket(master_ticket);
            if(slave_ticket_to_modify > 0)
            {
                if(PositionSelectByTicket(slave_ticket_to_modify))
                {
                    double current_sl = PositionGetDouble(POSITION_SL);
                    double current_tp = PositionGetDouble(POSITION_TP);
                    PrintFormat("ProcessCommand: Attempting MODIFY_HEDGE for master ticket %d (slave ticket %d). Current SL: %.5f->%.5f, Current TP: %.5f->%.5f", 
                                master_ticket, slave_ticket_to_modify, current_sl, new_slave_sl, current_tp, new_slave_tp);
                }
                
                bool modify_res = trade.PositionModify(slave_ticket_to_modify, new_slave_sl, new_slave_tp);
                if(modify_res)
                {
                    PrintFormat("ProcessCommand: MODIFY_HEDGE successful for slave ticket %d.", slave_ticket_to_modify);
                    g_ea_status_string = "Hedge SL/TP ModOK";
                    return true;
                }
                else
                {
                    PrintFormat("ProcessCommand: Failed to MODIFY_HEDGE for slave ticket %d. Error: %d, Retcode: %d, Comment: %s", 
                                slave_ticket_to_modify, GetLastError(), trade.ResultRetcode(), trade.ResultComment());
                    g_ea_status_string = "Hedge SL/TP ModFail";
                    return false;
                }
            }
            else
            {
                PrintFormat("ProcessCommand: MODIFY_HEDGE command for master ticket %d - no corresponding slave position found.", master_ticket);
                g_ea_status_string = "Modify: Slave N/F";
                return false;
            }
        }
        else
        {
            PrintFormat("ProcessCommand: Unknown command type '%s' received for master ticket %d", cmd_type, master_ticket);
            g_ea_status_string = "Unknown Cmd: " + cmd_type;
            return false;
        }
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
          
        int leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
        string server = AccountInfoString(ACCOUNT_SERVER);

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

        CreateMiniDashText(chartID, g_mini_dash_prefix + "Title", "SynPropEA2 Slave v" + "1.04", x_pos, y_start, clrGray);
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
    //| Clean up orphaned hedge positions                               |
    //+------------------------------------------------------------------+
    void CleanupOrphanedHedgePositions()
    {
        Print("CleanupOrphanedHedgePositions: Starting cleanup of orphaned hedge positions...");
        
        int total_positions = PositionsTotal();
        int cleaned_count = 0;
        
        for(int i = total_positions - 1; i >= 0; i--) // Iterate backwards to avoid index issues
        {
            if(PositionGetTicket(i) > 0)
            {
                if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber_Slave && PositionGetString(POSITION_SYMBOL) == _Symbol)
                {
                    ulong position_ticket = PositionGetTicket(i);
                    string position_comment = PositionGetString(POSITION_COMMENT);
                    
                    // Check if comment contains master ticket prefix
                    if(StringFind(position_comment, InpMasterTicketCommentPrefix) >= 0)
                    {
                        // Extract master ticket from comment
                        string master_ticket_str = StringSubstr(position_comment, StringLen(InpMasterTicketCommentPrefix));
                        ulong master_ticket = (ulong)StringToInteger(master_ticket_str);
                        
                        // Check if master position still exists (requires position history or active positions check)
                        // For now, we'll ask user to manually verify, but we can add auto-cleanup logic
                        PrintFormat("CleanupOrphanedHedgePositions: Found hedge position #%d for master ticket %d. Manual verification recommended.", 
                                   position_ticket, master_ticket);
                        
                        // Auto-cleanup logic: if this position has been open for a very long time without a master, close it
                        datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
                        datetime current_time = TimeCurrent();
                        int position_age_hours = (int)((current_time - position_time) / 3600);
                        
                        if(position_age_hours > 24) // Position older than 24 hours - likely orphaned
                        {
                            PrintFormat("CleanupOrphanedHedgePositions: Position #%d is %d hours old. Closing as likely orphaned.", 
                                       position_ticket, position_age_hours);
                            
                            if(trade.PositionClose(position_ticket))
                            {
                                cleaned_count++;
                                PrintFormat("CleanupOrphanedHedgePositions: Successfully closed orphaned position #%d", position_ticket);
                            }
                            else
                            {
                                PrintFormat("CleanupOrphanedHedgePositions: Failed to close position #%d. Error: %d", 
                                           position_ticket, GetLastError());
                            }
                        }
                    }
                    else
                    {
                        PrintFormat("CleanupOrphanedHedgePositions: WARNING - Found hedge position #%d without proper master linkage. Comment: %s", 
                                   position_ticket, position_comment);
                        
                        // These are definitely orphaned - close them
                        if(trade.PositionClose(position_ticket))
                        {
                            cleaned_count++;
                            PrintFormat("CleanupOrphanedHedgePositions: Successfully closed orphaned position #%d (no master link)", position_ticket);
                        }
                        else
                        {
                            PrintFormat("CleanupOrphanedHedgePositions: Failed to close orphaned position #%d. Error: %d", 
                                       position_ticket, GetLastError());
                        }
                    }
                }
            }
        }
        
        if(cleaned_count > 0)
        {
            PrintFormat("CleanupOrphanedHedgePositions: Cleaned up %d orphaned hedge positions.", cleaned_count);
        }
        else
        {
            Print("CleanupOrphanedHedgePositions: No orphaned positions found to clean up.");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Check for orphaned hedge positions on startup                    |
    //+------------------------------------------------------------------+
    void CheckForOrphanedHedgePositions()
    {
        Print("CheckForOrphanedHedgePositions: Scanning for hedge positions without proper master linkage...");
        
        int total_positions = PositionsTotal();
        int orphaned_count = 0;
        int old_positions = 0;
        
        for(int i = 0; i < total_positions; i++)
        {
            if(PositionGetTicket(i) > 0)
            {
                if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber_Slave && PositionGetString(POSITION_SYMBOL) == _Symbol)
                {
                    ulong position_ticket = PositionGetTicket(i);
                    string position_comment = PositionGetString(POSITION_COMMENT);
                    datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
                    int position_age_hours = (int)((TimeCurrent() - position_time) / 3600);
                    
                    // Check if comment contains master ticket prefix
                    if(StringFind(position_comment, InpMasterTicketCommentPrefix) >= 0)
                    {
                        // Extract master ticket from comment
                        string master_ticket_str = StringSubstr(position_comment, StringLen(InpMasterTicketCommentPrefix));
                        ulong master_ticket = (ulong)StringToInteger(master_ticket_str);
                        
                        if(position_age_hours > 24)
                        {
                            old_positions++;
                            PrintFormat("CheckForOrphanedHedgePositions: Found OLD hedge position #%d (age: %d hours) linked to master ticket %d. Comment: %s", 
                                       position_ticket, position_age_hours, master_ticket, position_comment);
                        }
                        else
                        {
                            PrintFormat("CheckForOrphanedHedgePositions: Found hedge position #%d linked to master ticket %d. Comment: %s", 
                                       position_ticket, master_ticket, position_comment);
                        }
                    }
                    else
                    {
                        orphaned_count++;
                        PrintFormat("CheckForOrphanedHedgePositions: WARNING - Found orphaned hedge position #%d without proper master linkage. Comment: %s", 
                                   position_ticket, position_comment);
                    }
                }
            }
        }
        
        if(orphaned_count > 0 || old_positions > 0)
        {
            PrintFormat("CheckForOrphanedHedgePositions: Found %d orphaned and %d old hedge positions. Consider running cleanup.", orphaned_count, old_positions);
            
            // Auto-cleanup if there are clearly orphaned positions (no master link) or very old positions
            if(orphaned_count > 0 || old_positions > 0)
            {
                Print("CheckForOrphanedHedgePositions: Starting automatic cleanup of suspicious positions...");
                CleanupOrphanedHedgePositions();
            }
        }
        else
        {
            Print("CheckForOrphanedHedgePositions: No orphaned hedge positions found. System integrity intact.");
        }
    }
    //+------------------------------------------------------------------+ 
