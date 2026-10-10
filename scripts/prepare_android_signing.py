#!/usr/bin/env python3
"""Generate a local Android upload key without printing its password or replacing existing keys."""
from pathlib import Path
import os,secrets,subprocess
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'config/signing';folder.mkdir(mode=0o700,exist_ok=True)
key=folder/'petfriendly-upload.jks';properties=ROOT/'android/key.properties'
if key.exists() or properties.exists():raise SystemExit('Signing files already exist; preserved unchanged.')
password=secrets.token_urlsafe(48);password_file=folder/'.key-password'
fd=os.open(password_file,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
with os.fdopen(fd,'w') as f:f.write(password+'\n')
java=subprocess.check_output(['/usr/libexec/java_home','-v','17'],text=True).strip()
try:
 result=subprocess.run([java+'/bin/keytool','-genkeypair','-keystore',str(key),'-storetype','JKS','-alias','upload','-keyalg','RSA','-keysize','3072','-validity','10000','-dname','CN=PetFriendly Upload, O=PetFriendly','-storepass:file',str(password_file),'-keypass:file',str(password_file)],capture_output=True)
 if result.returncode:raise SystemExit('Key generation failed; no credential values printed.')
 key.chmod(0o600)
 fd=os.open(properties,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
 with os.fdopen(fd,'w') as f:f.write('storeFile=../../config/signing/petfriendly-upload.jks\nkeyAlias=upload\nstorePassword='+password+'\nkeyPassword='+password+'\n')
 print('Local Android upload key generated. Keystore and properties are private and excluded from Git. Back up both before publishing.')
finally:password_file.unlink(missing_ok=True)
