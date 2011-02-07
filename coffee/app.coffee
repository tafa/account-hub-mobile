
tabs = {}
w = {}
tab_window_names = {
  transfers: [
    'rec_status'
    'rec_qr'
    'rec_details'
    'rec_numpad'
    'pay_initial'
    'transfers'
  ]
  accounts: [
    'add_account_choose_service'
    'add_account'
    'accounts'
  ]
}
w_tab_namemap = {}
for own tabName, v of tab_window_names
  for windowName in v
    w_tab_namemap[windowName] = tabName


#### Helpers

encodeParams = (params) ->
  (for own k, v of params
    encodeURIComponent(k) + '=' + encodeURIComponent(k)).join('&')

simpleGet = (url, params, callback) ->
  url = url + "?" + encodeParams(params)
  req = Titanium.Network.createHTTPClient()
  req.onload = () ->
    callback null, @responseText
  req.open 'GET', url
  req.send()

simplePost = (url, params, callback) ->
  url = url
  req = Titanium.Network.createHTTPClient()
  req.onload = () ->
    callback null, @responseText
  req.open 'POST', url
  req.setRequestHeader 'Content-Type', 'application/json'
  req.send JSON.stringify params

penniesToString = (pennies) ->
  pennies2 = (pennies % 100)
  right = if pennies2 >= 10
    '' + pennies2
  else
    '0' + pennies2
  Math.floor(pennies / 100) + '.' + right

processOpt = (opt) ->
  
  opt2 = {}
  listeners = []
  
  for own k, v of opt
    if (typeof v) == 'function'
      listeners.push [k, v]
    else if k == 'xywh'
      [opt2.left, opt2.top] = opt.xywh
      opt2.width = opt.xywh[2] if opt.xywh.length > 2
      opt2.height = opt.xywh[3] if opt.xywh.length > 3
    else
      opt2[k] = v
  
  [listeners, opt2]

create = (name, opt) ->
  [listeners, opt] = processOpt opt
  x = Titanium.UI["create#{name}"] opt
  for [k, v] in listeners
    x.addEventListener k, v
  x

Button = (opt) -> create 'Button', opt
Label = (opt) -> create 'Label', opt
TextField = (opt) -> create 'TextField', opt
Window = (opt) -> create 'Window', opt
TableView = (opt) -> create 'TableView', opt
Tab = (opt) -> create 'Tab', opt


class InvoicePosting
  
  constructor: (@invoice) ->
    @api "post", {invoice: invoice}, (y) ->
      @secret_invoice_token = y.secret_invoice_token
  
  withdraw: () ->
    if @secret_invoice_token
      api "withdraw", {secret_invoice_token: @secret_invoice_token}, (y) ->
    else
      #HANDLE: set callback
  
  api: (name, x, callback) ->
    apiRoot = "http://localhost:8000/api/" # TODO
    simplePost "#{apiRoot}#{name}.js", x, (j) ->
      y = JSON.parse j
      callback y



class Controller
  
  setRecAmountPennies: (pennies) ->
    @rec_details__label.text = "Amount: #{penniesToString pennies}"



controller = new Controller


open = (windowName) ->
  tabName = w_tab_namemap[windowName]
  tabs[tabName].open w[windowName], {animated: true}


#### Windows

w.rec_status = () ->
  win = Window
    title: 'Status'
  
  win

w.rec_qr = () ->
  win = Window
    title: 'Invoice QR'
  
  
  win

w.rec_details = () ->
  win = Window
    title: "Details"
  
  win.add controller.rec_details__label = Label
    text: ""
    xywh: [10, 30, 280, 30]
    color: '#FFF'
  
  
  win.add Button
    title: 'Show QR Code'
    xywh: [15, 200, 200, 40]
    click: () ->
      open 'rec_qr'
  
  win.add Button
    title: 'Post Invoice'
    xywh: [15, 270, 200, 40]
    click: () ->
      open 'rec_status'
  
  win

w.rec_numpad = () ->
  
  win = Window
    title: 'Amount'
  
  class NumpadController
    
    constructor: () ->
      @clear()
    
    numberClicked: (title) ->
      @digits.push title
      @updateText()
      1
    
    clear: () ->
      @digits = []
      @updateText()
      1
    
    setLabel: (@label) ->
      @updateText()
    
    updateText: () ->
      if @label
        @label.text = penniesToString @getPennies()
        1
    
    getPennies: () ->
      if @digits.length == 0
        0
      else
        parseInt @digits.join(''), 10
  
  numpad = new NumpadController()
  
  label = Label
    text: '125.34'
    top: 10
    color: '#FFF'
  
  win.add label
  numpad.setLabel label
  
  win.add Button
    title: "Clear"
    xywh: [10, 50, (50 + 10 + 50), 40]
    click: () ->
      numpad.clear()
  
  win.add Button
    title: "Enter"
    xywh: [200, 50, (50 + 10 + 50), 40]
    click: () ->
      controller.setRecAmountPennies numpad.getPennies()
      open 'rec_details'
  
  f = (title, x, y) ->
    win.add Button
      title: title
      xywh: [50 + x * 70, 120 + y * 60, 60, 50]
      click: () ->
        numpad.numberClicked title
  
  f "1", 0, 0
  f "2", 1, 0
  f "3", 2, 0
  f "4", 0, 1
  f "5", 1, 1
  f "6", 2, 1
  f "7", 0, 2
  f "8", 1, 2
  f "9", 2, 2
  f "0", 0, 3
  
  win

w.pay_initial = () ->
  win = Window
    title: 'Pay'
    backgroundColor: 'white'
  
  
  data = [
    {title:"XL Coffee, 4 timbits"}
  ]
  win.add TableView
    data: data
    style: Titanium.UI.iPhone.TableViewStyle.PLAIN
    click: (e) ->
      
  
  win

w.transfers = () ->
  win = Window
    title: 'Transfer'
    backgroundColor: 'black'
  
  win.add Button
    title: "Receive"
    xywh: [20, 90, 270, 40]
    click: () ->
      open 'rec_numpad'
  
  win.add Button
    title: "Pay"
    xywh: [20, 90 + 120, 270, 40]
    click: () ->
      open 'pay_initial'
  
  win


w.add_account_choose_service = () ->
  
  win = Window
      title: 'Choose Service'
      backgroundColor: 'black'
  
  data = [
    Ti.UI.createPickerRow {title:'Bitcoin-Central.net', custom_item:'b'}
    Ti.UI.createPickerRow {title:'MyBitcoin.com', custom_item:'2'}
  ]
  picker = Ti.UI.createPicker()
  picker.selectionIndicator = true
  picker.add data
  picker.setSelectedRow 0, 1, true
  picker.addEventListener 'change', (e) ->
    Titanium.API.info(e.rowIndex + ', ' + e.columnIndex + ': ' + e.row.custom_item)
  
  win.add picker
  win

w.add_account = () ->
  win = Window
      title: 'Add Account'
      backgroundColor: '#555'
  
  _Label = (opt) ->
    opt.color = '#FFF'
    Label opt
  
  # Service
  win.add _Label
    text: 'Service'
    xywh: [20, 20, 250, 'auto']
  
  win.add Button
    title: "localhost >"
    xywh: [20, 55, 270, 40]
    click: () ->
      open 'add_account_choose_service'
  
  # Account
  win.add _Label
    text: 'Account'
    xywh: [20, 100, 250, 'auto']
  
  win.add TextField
    borderStyle: Titanium.UI.INPUT_BORDERSTYLE_ROUNDED
    xywh: [20, 120, 270, 40]
  
  # Password
  win.add _Label
    text: 'Password'
    xywh: [20, 180, 250, 'auto']
  
  win.add TextField
    borderStyle: Titanium.UI.INPUT_BORDERSTYLE_ROUNDED
    xywh: [20, 200, 270, 40]
  
  win.add Button
    title: "Add Account"
    xywh: [20, 270, 270, 40]
    click: () ->
      
  
  win

w.accounts = () ->
  win = Window
      title: 'Accounts'
      backgroundColor: '#fff'
  
  win.leftNavButton = Button
    title: "Edit"
    click: () ->
      
  
  win.rightNavButton = Button
    systemButton: Titanium.UI.iPhone.SystemButton.ADD
    click: () ->
      open 'add_account'
  
  data = [
    {title:"foo", token: "lksjdf"}
    {title:"bar", token: "kjdhsfb"}
  ]
  tableview = TableView
    data: data
    style: Titanium.UI.iPhone.TableViewStyle.PLAIN
    click: (e) ->
      
  
  win.add tableview
  win


#### Tabs


tabs.transfers = () ->
  Tab
    icon: 'KS_nav_ui.png'
    title: 'Transfers'
    window: w.transfers

tabs.accounts = () ->
  Tab
    icon: 'KS_nav_ui.png'
    title: 'Accounts'
    window: w.accounts


for own k, f of w
  w[k] = f()
for own k, f of tabs
  tabs[k] = f()

Titanium.UI.setBackgroundColor '#000'

tabGroup = Titanium.UI.createTabGroup()
tabGroup.addTab tabs.transfers
tabGroup.addTab tabs.accounts
tabGroup.open()
