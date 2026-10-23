#!/usr/bin/env python3
import json, socket, threading, time, uuid, sqlite3, hashlib, os

HOST = '0.0.0.0'
PORT = 4010
DB_PATH = os.path.join(os.path.dirname(__file__), 'dragon_realm.db')
clients = {}
lock = threading.Lock()

def db_init():
    con = sqlite3.connect(DB_PATH)
    con.execute('''CREATE TABLE IF NOT EXISTS accounts (
        username TEXT PRIMARY KEY,
        password_hash TEXT,
        power INTEGER NOT NULL DEFAULT 10,
        zone TEXT NOT NULL DEFAULT 'valley',
        x REAL NOT NULL DEFAULT 260,
        y REAL NOT NULL DEFAULT 610,
        zeni INTEGER NOT NULL DEFAULT 80,
        updated_at REAL NOT NULL
    )''')
    con.commit(); con.close()

def password_hash(password: str) -> str:
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

def load_account(username: str):
    con = sqlite3.connect(DB_PATH)
    row = con.execute('SELECT username, power, zone, x, y, zeni FROM accounts WHERE username=?', (username,)).fetchone()
    con.close()
    return row

def save_account(c):
    username = c['name'][:20]
    if not username: return
    con = sqlite3.connect(DB_PATH)
    con.execute('''INSERT INTO accounts(username, password_hash, power, zone, x, y, zeni, updated_at)
                   VALUES(?,?,?,?,?,?,?,?)
                   ON CONFLICT(username) DO UPDATE SET power=excluded.power, zone=excluded.zone,
                   x=excluded.x, y=excluded.y, zeni=excluded.zeni, updated_at=excluded.updated_at''',
                (username, c.get('password_hash',''), c['power'], c['zone'], c['x'], c['y'], c['zeni'], time.time()))
    con.commit(); con.close()

def send(sock, payload):
    raw = (json.dumps(payload, separators=(',', ':')) + '\n').encode()
    sock.sendall(raw)

def broadcast(payload, except_sock=None):
    dead=[]
    with lock:
        items=list(clients.items())
    for cid, c in items:
        if c['sock'] is except_sock:
            continue
        try:
            send(c['sock'], payload)
        except OSError:
            dead.append(cid)
    for cid in dead:
        remove_client(cid)

def state_payload():
    with lock:
        players=[]
        for cid, c in clients.items():
            players.append({
                'id': cid, 'name': c['name'], 'x': c['x'], 'y': c['y'],
                'zone': c['zone'], 'power': c['power'],
            })
    return {'type':'STATE', 'players':players}

def remove_client(cid):
    with lock:
        c=clients.pop(cid,None)
    if c:
        try: save_account(c)
        except Exception: pass
        try: c['sock'].close()
        except OSError: pass
        broadcast({'type':'PLAYER_LEAVE','id':cid})

def client_thread(sock, addr):
    cid=uuid.uuid4().hex[:8]
    client={'sock':sock,'addr':addr,'name':'Guerrero','x':260.0,'y':610.0,'zone':'valley','power':10,'zeni':80,'password_hash':''}
    with lock: clients[cid]=client
    try:
        send(sock, {'type':'WELCOME','id':cid,'server':'TIERRA-01','motd':'Dragon Realm development server'})
        broadcast({'type':'PLAYER_JOIN','id':cid,'name':client['name']}, sock)
        buffer=b''
        while True:
            chunk=sock.recv(4096)
            if not chunk: break
            buffer += chunk
            while b'\n' in buffer:
                raw,buffer=buffer.split(b'\n',1)
                if not raw: continue
                try: data=json.loads(raw.decode())
                except Exception: continue
                typ=str(data.get('type',''))
                if typ=='AUTH':
                    name=str(data.get('name','Guerrero')).strip()[:20] or 'Guerrero'
                    client['name']=name
                    client['power']=max(10,int(data.get('power',10)))
                    client['zone']=str(data.get('zone','valley'))
                    row=load_account(name)
                    if row:
                        client['power']=int(row[1]); client['zone']=str(row[2]); client['x']=float(row[3]); client['y']=float(row[4]); client['zeni']=int(row[5])
                    save_account(client)
                    send(sock, {'type':'AUTH_OK','name':client['name'],'power':client['power'],'zone':client['zone'],'x':client['x'],'y':client['y'],'zeni':client['zeni']})
                elif typ=='MOVE':
                    try:
                        x=float(data.get('x',client['x'])); y=float(data.get('y',client['y']))
                        if -10000 < x < 10000 and -1000 < y < 3000:
                            client['x']=x; client['y']=y
                            client['zone']=str(data.get('zone',client['zone']))
                    except (ValueError,TypeError):
                        pass
                elif typ=='CHAT':
                    text=str(data.get('text','')).strip()[:160]
                    if text:
                        broadcast({'type':'CHAT','id':cid,'name':client['name'],'text':text,'zone':client['zone']})
                elif typ=='PING':
                    send(sock,{'type':'PONG','t':data.get('t',0)})
                elif typ=='ACTION':
                    action=str(data.get('action',''))[:40]
                    broadcast({'type':'ACTION','id':cid,'action':action,'zone':client['zone']}, sock)
    finally:
        remove_client(cid)

def ticker():
    while True:
        time.sleep(0.1)
        broadcast(state_payload())

def main():
    db_init()
    server=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
    server.bind((HOST,PORT)); server.listen(32)
    print(f'Dragon Realm server listening on {HOST}:{PORT}', flush=True)
    print(f'Persistent development DB: {DB_PATH}', flush=True)
    threading.Thread(target=ticker,daemon=True).start()
    while True:
        sock,addr=server.accept()
        threading.Thread(target=client_thread,args=(sock,addr),daemon=True).start()

if __name__ == '__main__':
    main()
