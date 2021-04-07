//
//  ViewController.swift
//  Soccer_memo
//
//  Created by 宮崎直久 on 2021/01/02.
//

import UIKit
import RealmSwift

private let unselectedRow = -1

//クラス定義に UITextFieldDelegate プロトコルを追加。（子クラス名: 親クラス名）
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    //確定ボタンがタップされたイベントでは、入力されたメモをメモ一覧へ反映するメソッドを呼び出すように実装。
    @IBAction func confirmButton(_ sender: Any) {
        applyMemo()
    }
    @IBOutlet weak var buttonEnabled: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var player_name: UILabel!
    @IBOutlet weak var memoListView: UITableView!
    //画面タップでキーボードを下げる
    @IBAction func tapView(_ sender: UITapGestureRecognizer) {
        //編集終了でキーボードを下げる
        view.endEditing(true)
    }
    //メモした内容を保持しておくString配列memoList
    var memoList: [String] = []
    //編集中の行番号を保持する editRow をメンバ変数として定義
    var editRow: Int = unselectedRow
    // モデルクラスを使用し、取得データを格納する変数を作成
    var tableCells: Results<MemoModel>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        // Realmインスタンス取得
        let realm = try! Realm()
        // データ全権取得
        print("--------------------")
        print(realm.objects(MemoModel.self).count)
        self.tableCells = realm.objects(MemoModel.self)
        memoListView.reloadData()
        //タイトル名設定
        navigationItem.title = "Player Scoring"
        self.memoListView.delegate = self
        self.memoListView.dataSource = self
        // メモ一覧で表示するセルを識別するIDの登録処理を追加。
        memoListView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        textField.text = ""
        buttonEnabled.isEnabled = false
        textField.addTarget(self, action:#selector(textFieldDidChange),for: UIControl.Event.editingChanged)
        //placeholderを装飾する
        let attributes: [NSAttributedString.Key : Any] = [
          .foregroundColor : UIColor.lightGray // カラー
        ]
        //placeholderを設定
        textField.attributedPlaceholder = NSAttributedString(string: "チーム名を入力", attributes: attributes)
    }
    
    //実行中のアプリがiPhoneのメモリを使いすぎた際に呼び出される。
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func textFieldDidChange(){
        buttonEnabled.isEnabled = !(textField.text?.isEmpty ?? true)
    }
    
    //セクションごとの行数を返す。
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCells.count
    }
    
    //メモ一覧が表示する内容を返すメソッドでは宣言したmemoListが保持している行番号に対応したメモを返すように実装。
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        if indexPath.row >= tableCells.count {
            return cell
        }
        cell.textLabel?.text = tableCells[indexPath.row].memo
        return cell
    }
    
    //メモ一覧のセルが選択されたイベント
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= memoList.count {
            return
        }
        //遷移先ViewControllerのインスタンス取得
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "playerData") as! DetailViewController
        //TableViewの値を遷移先に値渡し
        detailViewController.data = memoList[indexPath.row]
        //画面遷移
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
    
    //セルの削除処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            // Realmインスタンス取得
            let realm = try! Realm()
            // データを削除
            try! realm.write {
                realm.delete(tableCells[indexPath.row])
            }
            //セルの削除
            self.tableCells = realm.objects(MemoModel.self)
            memoListView.reloadData()
        }
    }
    //TextFieldでreturn(改行)されたイベントでは確定ボタンタップイベントと同様に、入力されたメモをメモ一覧へ反映するメソッドを呼び出すように実装。
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyMemo()
        return true
    }
    
    //メモの入力を確定するメソッドでは、追加モードか編集モードかを判定し、memoListに対して入力テキストの追加、または上書きを行い、 編集モードから追加モードへの変更、メモ一覧の更新を行うように実装。
    func applyMemo() {
        if textField.text == nil {
            return
        }
        
        if editRow == unselectedRow {
            //メモにテキストに入力された値を追加する
            memoList.append(textField.text!)
        } else {
            memoList[editRow] = textField.text!
        }
        buttonEnabled.isEnabled = false
        editRow = unselectedRow
        // モデルクラスをインスタンス化
        let tableCell:MemoModel = MemoModel()
        // Realmインスタンス取得
        let realm = try! Realm()
        // テキストフィールドの名前を入れる
        tableCell.memo = self.textField.text
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        // テキストフィールドの情報をデータベースに追加
        try! realm.write {
            realm.add(tableCell)
        }
        //TextField の内容のクリア
        textField.text = ""
        //メモリリストビューの行とセクションを再読み込み
        self.tableCells = realm.objects(MemoModel.self)
        memoListView.reloadData()
    }
}

