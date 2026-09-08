#property copyright "PCCONTRACT"
#property version   "1.02"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Parâmetros de Entrada
input group "Configurações Gerais"
input ulong  InpMagicNumber = 123456;     // Magic Number
input double InpTargetProfit = 500.0;     // Meta de Lucro Global ($) [0 = Desativar]
input double InpMaxLoss = -200.0;         // Limite de Perda Global ($) [0 = Desativar]

//--- Estrutura do Painel PCCONTRACT
class CPcContractPanel : public CAppDialog
{
private:
   CButton m_btnBuy;      
   CButton m_btnSell;     
   CEdit   m_editLot;     
   
   CLabel  m_lblSL;
   CEdit   m_editSL;
   CLabel  m_lblTP;
   CEdit   m_editTP;
   
   CButton m_btnCloseAll;
   CLabel  m_lblProfit;

   CTrade  m_trade;       

public:
   virtual bool Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2);
   
   EVENT_MAP_BEGIN(CPcContractPanel)
      ON_EVENT(ON_CLICK, m_btnBuy, OnClickBuy)
      ON_EVENT(ON_CLICK, m_btnSell, OnClickSell)
      ON_EVENT(ON_CLICK, m_btnCloseAll, OnClickCloseAll)
   EVENT_MAP_END(CAppDialog)

   void InitTrade();
   void OnClickBuy();
   void OnClickSell();
   void OnClickCloseAll();
   void UpdateProfit();
   void CheckGlobalProfit();
};

void CPcContractPanel::InitTrade()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(50);
}

//--- Desenhando a Interface
bool CPcContractPanel::Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2)
{
   if(!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2)) return(false);

   // Botão de Venda
   if(!m_btnSell.Create(chart, name+"_Sell", subwin, 20, 40, 110, 100)) return false;
   m_btnSell.Text("SELL");
   m_btnSell.ColorBackground(clrCrimson);
   m_btnSell.Color(clrWhite);
   Add(m_btnSell);

   // Caixa de Lote
   if(!m_editLot.Create(chart, name+"_Lot", subwin, 120, 55, 180, 85)) return false;
   m_editLot.Text("1.0"); // Padrão ajustado para B3
   Add(m_editLot);

   // Botão de Compra
   if(!m_btnBuy.Create(chart, name+"_Buy", subwin, 190, 40, 280, 100)) return false;
   m_btnBuy.Text("BUY");
   m_btnBuy.ColorBackground(clrForestGreen);
   m_btnBuy.Color(clrWhite);
   Add(m_btnBuy);

   // Rótulo Stop Loss
   if(!m_lblSL.Create(chart, name+"_lblSL", subwin, 20, 110, 140, 125)) return false;
   m_lblSL.Text("Stop Loss (pontos)");
   Add(m_lblSL);

   // Caixa de Stop Loss
   if(!m_editSL.Create(chart, name+"_SL", subwin, 20, 125, 110, 145)) return false;
   m_editSL.Text("1000"); // Padrão maior para B3
   Add(m_editSL);

   // Rótulo Take Profit
   if(!m_lblTP.Create(chart, name+"_lblTP", subwin, 170, 110, 280, 125)) return false;
   m_lblTP.Text("Take Profit (pontos)");
   Add(m_lblTP);

   // Caixa de Take Profit
   if(!m_editTP.Create(chart, name+"_TP", subwin, 190, 125, 280, 145)) return false;
   m_editTP.Text("2000"); // Padrão maior para B3
   Add(m_editTP);

   // Botão Fechar Tudo
   if(!m_btnCloseAll.Create(chart, name+"_CloseAll", subwin, 20, 155, 280, 185)) return false;
   m_btnCloseAll.Text("FECHAR TUDO");
   m_btnCloseAll.ColorBackground(clrDarkOrange);
   m_btnCloseAll.Color(clrWhite);
   Add(m_btnCloseAll);

   // Rótulo de Lucro
   if(!m_lblProfit.Create(chart, name+"_lblProfit", subwin, 20, 195, 280, 215)) return false;
   m_lblProfit.Text("Lucro Flutuante: 0.00");
   Add(m_lblProfit);

   return(true);
}

//--- Execução de Ordens
void CPcContractPanel::OnClickBuy()
{
   double lot = StringToDouble(m_editLot.Text());
   double sl_points = StringToDouble(m_editSL.Text());
   double tp_points = StringToDouble(m_editTP.Text());
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   
   double ask = tick.ask;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double sl = (sl_points > 0) ? NormalizeDouble(ask - (sl_points * point), digits) : 0;
   double tp = (tp_points > 0) ? NormalizeDouble(ask + (tp_points * point), digits) : 0;
   
   if(!m_trade.Buy(lot, _Symbol, ask, sl, tp))
   {
      Print("Erro BUY: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
   }
}

void CPcContractPanel::OnClickSell()
{
   double lot = StringToDouble(m_editLot.Text());
   double sl_points = StringToDouble(m_editSL.Text());
   double tp_points = StringToDouble(m_editTP.Text());
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   
   double bid = tick.bid;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double sl = (sl_points > 0) ? NormalizeDouble(bid + (sl_points * point), digits) : 0;
   double tp = (tp_points > 0) ? NormalizeDouble(bid - (tp_points * point), digits) : 0;
   
   if(!m_trade.Sell(lot, _Symbol, bid, sl, tp))
   {
      Print("Erro SELL: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
   }
}

//--- Fechar Tudo
void CPcContractPanel::OnClickCloseAll()
{
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
         {
            m_trade.PositionClose(pos.Ticket());
         }
      }
   }
}

//--- Atualizar Lucro Flutuante
void CPcContractPanel::UpdateProfit()
{
   double profit = 0.0;
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
         {
            profit += pos.Profit() + pos.Swap() + pos.Commission();
         }
      }
   }
   m_lblProfit.Text("Lucro Flutuante: " + DoubleToString(profit, 2));
}

//--- Checar Meta e Limite de Perda Global
void CPcContractPanel::CheckGlobalProfit()
{
   double profit = 0.0;
   CPositionInfo pos;
   bool has_positions = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
         {
            profit += pos.Profit() + pos.Swap() + pos.Commission();
            has_positions = true;
         }
      }
   }
   
   if(has_positions)
   {
      if(InpTargetProfit > 0 && profit >= InpTargetProfit)
      {
         Print("Meta de lucro atingida! Fechando todas as ordens.");
         OnClickCloseAll();
      }
      else if(InpMaxLoss < 0 && profit <= InpMaxLoss)
      {
         Print("Limite de perda atingido! Fechando todas as ordens.");
         OnClickCloseAll();
      }
   }
}

//--- Instanciando
CPcContractPanel ExtPanel;

int OnInit()
{
   ExtPanel.InitTrade(); // Inicializa Magic Number
   
   if(!ExtPanel.Create(0, "PCCONTRACT", 0, 50, 50, 350, 310))
      return(INIT_FAILED);
      
   ExtPanel.Run();
   EventSetTimer(1);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ExtPanel.Destroy(reason);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   ExtPanel.ChartEvent(id, lparam, dparam, sparam);
}

void OnTimer()
{
   ExtPanel.UpdateProfit();
}

void OnTick()
{
   ExtPanel.CheckGlobalProfit();
}