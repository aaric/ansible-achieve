# Ansible

> Ansible Learning.

## 1. Install

```bash
sudo yum install -y ansible
```

## 2. Usage

> [User Guide - All modules - v2.9](https://docs.ansible.com/ansible/2.9/modules/list_of_all_modules.html)

|No.|Hostname|IP Address|Remark|
|:-:|:-:|:-:|---|
|1|k8s-master|`172.16.80.20`|*ansible installed*|
|2|k8s-node01|`172.16.80.21`||
|3|k8s-node02|`172.16.80.22`||

### 2.1 inventory

```bash
# 1. password
cat > inventory.ini <<-'EOF'
[agents]
k8s-node01 ansible_connection=ssh ansible_user=vagrant ansible_password=vagrant
k8s-node02 ansible_connection=ssh ansible_user=vagrant ansible_password=vagrant
EOF
ansible agents -m ping -i inventory.ini

# 2. rsa
cat > inventory.ini <<-'EOF'
[agents]
k8s-node01 ansible_connection=ssh ansible_user=vagrant
k8s-node02 ansible_connection=ssh ansible_user=vagrant
EOF
ansible agents -m ping -i inventory.ini
```

### 2.2 playbook

```bash
# inventory.ini
cat > inventory.ini <<-'EOF'
[agents]
k8s-node01 ansible_connection=ssh ansible_user=vagrant
k8s-node02 ansible_connection=ssh ansible_user=vagrant
EOF

# test.yml
cat > vars/test.yml <<-'EOF'
greetings: hello vars_files
EOF

# helloworld.yml
cat > helloworld.yml <<-'EOF'
- name: hello world
  hosts: agents
  vars:
    greetings: hello vars
  vars_files:
    - vars/test.yml
  tasks:
    - name: test debug
      debug:
        msg: "{{ greetings }}"
EOF

# playbook
ansible-playbook helloworld.yml -i inventory.ini
```

### 2.3 loop

```bash
# inventory.ini
cat > inventory.ini <<-'EOF'
[agents]
k8s-node01 ansible_connection=ssh ansible_user=vagrant
k8s-node02 ansible_connection=ssh ansible_user=vagrant
EOF

# helloloop.yml
cat > helloloop.yml <<-'EOF'
- name: hello loop
  hosts: agents
  vars:
    numbers:
      - one
      - two
      - three
    letters:
      - a
      - b
  tasks:
    - name: test loop
      debug:
      #   msg: "{{ item }}"
      # with_items: "{{ numbers }}"
        msg: "{{ item[0] }} - {{ item[1] }}"
      with_nested:
        - "{{ numbers }}"
        - "{{ letters }}"
EOF

# playbook
ansible-playbook hellovars.yml -i inventory.ini
```

### 2.4 vars

```bash
# hosts
mkdir inventory/
cat > inventory/hosts <<-'EOF'
[agents]
k8s-node01
k8s-node02

[agents:vars]
ansible_connection=ssh
ansible_user=vagrant
EOF

# hellovars.yml
cat > hellovars.yml <<-'EOF'
- name: hello vars
  hosts: agents
  gather_facts: no
  tasks:
    - name: test vars
      debug:
        msg: "ansible_connection = {{ ansible_connection }}, ansible_user = {{ ansible_user }}"
EOF

# playbook
ansible-playbook hellovars.yml -i inventory/hosts
```

### 2.5 ansible.cfg

```bash
# hosts
# hellovars.yml
cp -r ../04-vars/* .

# ansible.cfg
cat > ansible.cfg <<-'EOF'
[defaults]
inventory = inventory/hosts
EOF

# playbook
ansible-playbook hellovars.yml
```

### 2.6 standard

```bash
# ansible.cfg
cat > ansible.cfg <<-'EOF'
[defaults]
inventory = inventory/hosts
EOF

# hosts
mkdir inventory/
cat > inventory/hosts <<-'EOF'
[agents]
k8s-node01
k8s-node02
EOF

# group_vars
mkdir group_vars/
cat > group_vars/agents.yml <<-'EOF'
ansible_connection: ssh
ansible_user: vagrant
EOF

# host_vars
mkdir host_vars/
cat > host_vars/k8s-node01.yml <<-'EOF'
linux_version: debian
EOF
cat > host_vars/k8s-node02.yml <<-'EOF'
linux_version: ubuntu
EOF

# site.yml
cat > site.yml <<-'EOF'
- name: hello standard
  hosts: agents
  gather_facts: no
  tasks:
    - name: test standard
      debug:
        msg: "linux_version = {{ linux_version }}"
EOF

# playbook
ansible-playbook site.yml
```

### 2.7 module-file

> [Jinja is a modern and designer-friendly templating language for Python.](https://jinja.palletsprojects.com/en/2.11.x/)

```bash
# standard
cp -r ../06-standard/* .

# test.txt
echo 'hello world' > test.txt

# jianja
mkdir templates/
cat > templates/test.j2 <<-'EOF'
[k8s]
{% for ip in range(21,31) %}
k8s-node{{ "%02d" | format(ip-20) }} - 172.16.80.{{ ip - 1 }}
{% endfor %}
EOF

# site.yml
cat > site.yml <<-'EOF'
- name: hello copy
  hosts: agents
  gather_facts: no
  tasks:
    - name: test create directory
      file:
        path: /home/vagrant/test
        state: directory
        #state: absent
    - name: test copy file to remote
      copy:
        src: test.txt
        dest: /home/vagrant/test/test.txt
        backup: yes
    - name: test jinja
      template:
        src: templates/test.j2
        dest: /home/vagrant/test/test.cfg
    - name: test copy remote file
      # ansible-doc -s fetch
      fetch:
        src: /home/vagrant/test/test.cfg
        dest: ./tmp/
        flat: yes
    - name: test uri
      uri:
        url: https://www.baidu.com
        return_content: yes
      register: result
    - name: print result
      debug:
        msg: "{{ result }}"
EOF

# playbook
ansible-playbook site.yml
ansible agents -m shell -a "cat /home/vagrant/test/test.txt"
ansible agents -m shell -a "cat /home/vagrant/test/test.cfg"
```

### 2.8 module-system

```bash
# standard
cp -r ../06-standard/* .

# gather_facts
ansible agents -m gather_facts --tree ./tmp/facts

# site.yml
cat > site.yml <<-'EOF'
- name: hello facts
  hosts: agents
  gather_facts: yes
  become: yes
  tasks:
    - name: test facts
      debug:
        msg: "{{ ansible_hostname }} : {{ ansible_distribution }} - {{ ansible_distribution_version }}"
    - name: test create group
      group:
        name: k8s
    - name: test create user
      user:
        name: k8sadmin
        password: "{{ 'k8sadmin' | password_hash('sha512') }}"
        group: k8s
    - name: test delete user
      user:
        name: k8sadmin
        state: absent
        remove: yes
    - name: test delete group
      group:
        name: k8s
        state: absent
EOF

# playbook
ansible-playbook site.yml
ansible agents -m shell -a "id k8sadmin"
```

### 2.9 module-packaging

```bash
# standard
cp -r ../06-standard/* .

# site.yml
cat > site.yml <<-'EOF'
- name: hello packaging
  hosts: agents
  gather_facts: yes
  become: yes
  tasks:
    # - name: test yum install
    #   yum:
    #     name: git
    #   when: ansible_facts['distribution'] == "CentOS"
    # - name: test yum remove
    #   yum:
    #     name: git
    #     state: absent
    #   when: ansible_facts['distribution'] == "CentOS"
    - name: test package install
      package:
        name: git
    - name: test package remove
      package:
        name: git
        state: absent
EOF

# playbook
ansible-playbook site.yml
ansible agents -m shell -a "git version"

# setup
ansible agents -m setup --tree ./tmp/facts
ansible agents -m setup -a "filter=ansible_distribution*"
```

## 3. FAQ

### 3.1 `Permission denied (publickey,gssapi-keyex,gssapi-with-mic).`

```bash
sudo vim /etc/ssh/sshd_config
'''
PasswordAuthentication yes
'''
sudo systemctl restart sshd
```

### 3.2 rsa login

```bash
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
ssh-copy-id vagrant@k8s-node01
ssh-copy-id vagrant@k8s-node02
````
