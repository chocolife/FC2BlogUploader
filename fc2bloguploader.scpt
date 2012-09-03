(*
ユーザー毎の初期設定
*)

--ユーザ名、もしくは登録しているメールアドレスを入れる　※必ず書き換えてください
property myID : "『ユーザ名』"

--アップロード時に自動的にサムネイルを作成するか（offの場合は""にする）
property createThumb : "on"

--アップロード時に作成されるサムネイルのサイズ（幅・高さ）
property thumbWidth : 250
property thumbHeight : 250

--同名のファイルが既にある場合、上書きするかどうか
-- 上書きする場合は"force"　別名で保存する場合は"rename"にする
property overwrite : "force"

(*
ユーザー毎の初期設定ここまで
*)


property myURL : "http://control.blog.fc2.com/control.php"
property msg1 : "管理画面のパスワードを入力" as Unicode text
property msg2 : "終了しました。" as Unicode text
property msg3 : "ログインに失敗しました。" as Unicode text
property cookiePath : " ~/Library/Cookies/fc2uploader_cookie.txt" ----保存するcookieのパス

on open drop
	activate me
	set myPass to text returned of (display dialog msg1 default answer "")
	
	----ログイン処理&Cookie保存
	set loginScript to "curl -d \"id=" & myID & "&pass=" & myPass & "&mode=admin&mode=logging&process=in\" -c " & cookiePath & " -L " & myURL & " | tail -n 300"
	set response_login to do shell script loginScript as string
	----パスワードの入力フォームがレスポンスに含まれていた場合、ログイン失敗と判定（ちょっとこのへんが微妙…）
	if response_login contains "input type=\"password\"" then
		beep
		display dialog msg3 with icon 0 buttons "OK" default button 1
		error number -128
	end if
	
	--POST時に送信するCRCの値を取得
	set getCrcScript to "curl -b " & cookiePath & " -d \"mode=control&process=upload\" -L " & myURL & " | grep 'name=\"crc\"' | sed 's/	*<input.*value=\"//' | sed 's/\".*'//"
	set returnedCrc to 1st paragraph of (do shell script getCrcScript as string)
	
	----メインループ
	repeat with theFile in drop
		tell application "Finder"
			set fPath to POSIX path of theFile as Unicode text
			set uploadScript to "curl -b " & cookiePath & " -F \"upfile[0]=@" & fPath & "\" -F thumb=" & createThumb
			set uploadScript to uploadScript & " -F width=" & thumbWidth & " -F height=" & thumbHeight & " -F overwrite=" & overwrite
			set uploadScript to uploadScript & " -F mode=control -F process=upload -F type=upload -F crc=" & returnedCrc & " -F insert=\"\" -L " & myURL
			do shell script uploadScript
		end tell
	end repeat
	beep
	display dialog msg2 default button 1 buttons "OK"
end open
