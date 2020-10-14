# coding: utf-8
import nfc

try:
    # リーダー利用開始
    clf = nfc.ContactlessFrontend('usb')
    # Express Cardチェック
    target = nfc.clf.RemoteTarget('212F')
    target.sensf_req = bytearray.fromhex('0000030000') # ExpressCard呼び出し用
    response = clf.sense(target, iterations=2, interval=0.01) # iterations=1だと認識しない
    # Express CardがなければFelicaチェック
    if response is None:
        target = nfc.clf.RemoteTarget('212F')
        response = clf.sense(target)
    # FelicaがなければTypeAチェック
    if response is None:
        target = nfc.clf.RemoteTarget('106A')
        response = clf.sense(target)
    # あればID取り出し
    if not response is None:
        tag = nfc.tag.activate(clf, response)
        id = str(tag.identifier).encode().hex().upper()
        print(id, end='')
    # リーダー利用完了
    clf.close()
except:
    # エラーを返す(先頭の!がエラーの印)
    print('!No Card Reader', end='')
