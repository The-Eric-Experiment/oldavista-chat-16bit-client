�
 TSMTPTESTFORM 0�  TPF0TSmtpTestFormSmtpTestFormLeftgTopIWidthHeight�Caption"SMTP Test - http://www.overbyte.beColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrder	PositionpoScreenCenterOnClose	FormCloseOnCreate
FormCreateOnShowFormShowPixelsPerInch`
TextHeight TMemoMsgMemoLeft Top� WidthHeightxHint#Enter the message text in this memoAlignalTopFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style Lines.StringsMsgMemo 
ParentFontParentShowHint
ScrollBarsssBothShowHint	TabOrder   TMemoDisplayMemoLeft Top�WidthHeight#HintThis memo shows info messagesAlignalClientFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style Lines.StringsDisplayMemo 
ParentFontParentShowHintReadOnly	
ScrollBarsssBothShowHint	TabOrder  TPanel
ToolsPanelLeft Top WidthHeight� AlignalTopTabOrder TLabelLabel1LeftTopWidth7HeightCaption	SMTP Host  TLabelLabel2Left6Top$WidthHeightCaptionFrom  TLabelLabel3Left� Top$WidthHeightCaptionTo  TLabelSubjectLeft)TopRWidth$HeightCaptionSubject  TLabelLabel4Left� TopWidthHeightCaptionPort  TLabelLabel5LeftTop� WidthBHeightCaptionMessage text:  TLabelLabel8Left� TopTWidthHeightCaptionSign  TLabelLabel9LeftToplWidth0HeightCaptionUsername  TLabelLabel10Left� ToplWidthHeightCaptionPass  TLabelLabel11Left	Top� WidthDHeightCaptionAuthentication  TLabelLabel12Left@Top<WidthHeightCaptionCc  TLabelLabel13Left� Top<WidthHeightCaptionBcc  TLabelLabel14Left� Top� WidthHeightCaptionPriority  TEditHostEditLeftPTopWidthyHeightHint"Mail server hostname or IP addressParentShowHintShowHint	TabOrder TextHostEdit  TEditFromEditLeftPTop WidthyHeightHintAuthor's EMailParentShowHintShowHint	TabOrderTextFromEdit  TEditToEditLeft� Top WidthyHeightHint$Destinators, delimited by semicolonsParentShowHintShowHint	TabOrderTextToEdit  TEditSubjectEditLeftPTopPWidthyHeightHintMessage subjectParentShowHintShowHint	TabOrderTextSubjectEdit  TEdit
SignOnEditLeft� TopPWidthyHeightHint#Signon message for the HELO commandParentShowHintShowHint	TabOrderText
SignOnEdit  TEditPortEditLeft� TopWidthyHeightHint!Mail server port (should be smtp)ParentShowHintShowHint	TabOrderTextPortEdit  TButtonClearDisplayButtonLeft�TopXWidthIHeightHintClear info message memoCaptionClear &InfoParentShowHintShowHint	TabOrderOnClickClearDisplayButtonClick  TButtonConnectButtonLeftpTopWidthIHeightHintConnect to the mail serverCaptionConnectParentShowHintShowHint	TabOrderOnClickConnectButtonClick  TButton
HeloButtonLeftpTopWidthIHeightHintSend the signon messageCaptionHeloParentShowHintShowHint	TabOrderOnClickHeloButtonClick  TButtonMailFromButtonLeftpTopXWidthIHeightHintSend the mail originatorCaptionMailFromParentShowHintShowHint	TabOrderOnClickMailFromButtonClick  TButtonRcptToButtonLeftpToplWidthIHeightHintSend the mail recipentsCaptionRcptToParentShowHintShowHint	TabOrderOnClickRcptToButtonClick  TButton
DataButtonLeftpTop� WidthIHeightHint!Send mail text and attached filesCaptionDataParentShowHintShowHint	TabOrderOnClickDataButtonClick  TButtonAbortButtonLeft�TopDWidthIHeightHint!Abort current operation and closeCaptionAbortParentShowHintShowHint	TabOrderOnClickAbortButtonClick  TButton
QuitButtonLeft�Top0WidthIHeightHintQuit mail serverCaptionQuitParentShowHintShowHint	TabOrderOnClickQuitButtonClick  TButton
MailButtonLeft�TopWidthIHeightHint"MailFrom, RcptTo and Data combinedCaptionMailParentShowHintShowHint	TabOrderOnClickMailButtonClick  TButton
OpenButtonLeft�TopWidthIHeightHintConnect and Helo combinedCaptionOpenParentShowHintShowHint	TabOrderOnClickOpenButtonClick  TEditUsernameEditLeftPTophWidthyHeightTabOrderTextUsernameEdit  TEditPasswordEditLeft� TophWidthyHeightTabOrder	TextPasswordEdit  	TComboBoxAuthComboBoxLeftPTop� WidthyHeightStylecsDropDownList
ItemHeightTabOrder
Items.StringsNonePlainLoginCramMD5CarmSHA1
AutoSelect   TButton
EhloButtonLeftpTop0WidthIHeightCaptionEhloTabOrderOnClickEhloButtonClick  TButton
AuthButtonLeftpTopDWidthIHeightCaptionAuthTabOrderOnClickAuthButtonClick  TEditCcEditLeftPTop8WidthyHeightTabOrderTextCcEdit  TEditBccEditLeft� Top8WidthyHeightTabOrderTextBccEdit  TButtonAllInOneButtonLeft�Top� WidthIHeightHintNConnect, Helo, MailFrom, RcptTo, Data and Quit all chained in a single action.Caption
All In OneParentShowHintShowHint	TabOrderOnClickAllInOneButtonClick  	TComboBoxPriorityComboBoxLeft� Top� WidthyHeightStylecsDropDownList
ItemHeightTabOrderItems.StringsNot specifiedHighestHighNormalLowLowest   	TCheckBoxConfirmCheckBoxLeft&Top� Width7Height	AlignmenttaLeftJustifyCaptionConfirmTabOrder   TPanelAttachPanelLeft Top1WidthHeightAlignalTopTabOrder TLabelLabel6LeftTopWidthCHeightCaptionAttached files:   TMemoFileAttachMemoLeft TopBWidthHeight1Hint*Enter the attached file path, one per lineAlignalTopFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style Lines.StringsFileAttachMemo 
ParentFontParentShowHint
ScrollBars
ssVerticalShowHint	TabOrder  TPanel	InfoPanelLeft TopsWidthHeightAlignalTopTabOrder TLabelLabel7LeftTopWidthGHeightCaptionInfo messages:   TSmtpCli
SmtpClientTag 	ShareModesmtpShareDenyWrite	LocalAddr0.0.0.0PortsmtpAuthTypesmtpAuthNoneHdrPrioritysmtpPriorityNoneCharSet
iso-8859-1ContentTypesmtpPlainText
OwnHeaders	OnDisplaySmtpClientDisplay	OnCommandSmtpClientDisplay
OnResponseSmtpClientDisplay	OnGetDataSmtpClientGetDataOnHeaderLineSmtpClientHeaderLineOnRequestDoneSmtpClientRequestDoneLeft�Top�    