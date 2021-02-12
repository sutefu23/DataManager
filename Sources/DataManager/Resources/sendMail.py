# coding: UTF-8

import sys
import base64
import smtplib
import ssl
from email.mime.text import MIMEText
from email.utils import formatdate

import mailConfig as config

try:
    if len(sys.argv) < 5:
        raise AttributeError("コマンドライン引数は最低5つ必要です（送信元メール、受信先メール、CC、タイトル、本文）")


    mail_from = sys.argv[1]

    mail_to = sys.argv[2]

    mail_cc = sys.argv[3]
    
    title = sys.argv[4]

    body = " ".join(sys.argv[5:]) #本文中に半角スペースが入ってる可能性を勘案

    charset = "utf-8"
    if charset == "utf-8":
        msg = MIMEText(body, "plain", charset)
    elif charset == "iso-2022-jp":
        msg = MIMEText(base64.b64encode(body.encode(charset, "ignore")), "plain", charset)


    """
    (2) MIMEメッセージに必要なヘッダを付ける
    """
    msg.replace_header("Content-Transfer-Encoding", "base64")
    msg["Subject"] = title
    msg["From"] = mail_from
    msg["To"] = mail_to
    msg["Cc"] = mail_cc
    msg["Bcc"] = ""
    msg["Date"] = formatdate(None,True)


    """
    (3) SMTPクライアントインスタンスを作成
    """
    host = config.host
    port = config.port
    method = config.method

    port = config.port
    if method == "noencrypt":
        smtpclient = smtplib.SMTP(host, port, timeout=10)
    elif method == "starttls":
        smtpclient = smtplib.SMTP(host, port, timeout=10)
        smtpclient.ehlo()
        smtpclient.starttls()
        smtpclient.ehlo()
    elif method == "ssl":
        context = ssl._create_unverified_context()
        smtpclient = smtplib.SMTP_SSL(host, port, timeout=10, context=context)
    smtpclient.set_debuglevel(2) # サーバとの通信のやり取りを出力してくれる


    """
    (4) サーバーにログインする
    """
    username = config.username
    password = config.password
    smtpclient.login(username, password)


    """
    (5) メールを送信する
    """
    smtpclient.send_message(msg)
    smtpclient.quit()
except:
    # エラーを返す(先頭の!がエラーの印)
    print('!SendMailError', end='')
