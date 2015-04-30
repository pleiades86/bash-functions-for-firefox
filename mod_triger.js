(function() {
    if ('mod_triger' in window) {
        var errorMsg = 'The name mod_triger has been used'; 
        if ('mod_info' in mod_triger
            && 'id' in mod_triger.mod_info
            && mod_triger.mod_info.id
            == 'ce9e3143-abee-4356-b1a1-2e0f27d037a7') {
            delete window.mod_triger;
        }
        else {
            throw errorMsg;
        }
    }
    
    mod_triger = {
        self: null,
        MsgStore: new Array(),
        Agents: new Array(),
        MsgReceived: {},
        MsgSent: {},
        MsgUnknown: {},

        known: {
            name: {
                msg: 'mod_triger message',
                ticket: 'mod_triger ticket',
                agent: 'mod_triger agent'
            },
            uuid: {
                mod_id: 'ce9e3143-abee-4356-b1a1-2e0f27d037a7',
                search_key: '73b60b75-380d-47d9-809d-908736450d86',
                ticket_id: '18d29b50-0a92-46a0-a2ca-fbc8fd036c00',
                msg_id: '5ef66e29-374e-4481-9a87-b42548e072c9',
                agent_id: '37937b4c-ac16-4ac1-ae9b-2f44279c5646',
                main_js_file_id: 'd1dd4608-9b65-4437-b9b1-0a67efe892d1',
                our_js_dir: '5a4863c7-ca1a-41a2-8737-c502da05a8c3'
            }
        },
        

        uuidgen: function() {
            var d = new Date().getTime();
            var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
                    .replace(/[xy]/g, function(c) {
                        var r = (d + Math.random()*16)%16 | 0;
                        d = Math.floor(d/16);
                        return (c=='x' ? r : (r&0x3|0x8)).toString(16);
                    });
            return uuid;
        },

        mod_info: {
            id: 'ce9e3143-abee-4356-b1a1-2e0f27d037a7',
            version: '0.01',
            author: 'xning',
            email: 'anzhou94@gmail.com',
            descr: 'JavaScript functions about HTML5 for mod_triger'
        },

        /*
         *  Agent(path)
         *  Agent(path, inserted_js_file_path)
         *  Agent(path, inserted_js_file_path, win)
         *  Agent(path, inserted_js_file_path, win, status)
         */
        Agent: function(path, inserted_js_file_path) {
            var i = arguments.length;
            this.path = '';
            this.js_file_path = '';
            this.win = null;
            this.status = 'need_open';
            this.is_the_js_file_insert = false;
            this.is_control_agent = false;
            this.data_structure_id = mod_triger.known.uuid.agent_id;
            this.data_structure_name = mod_triger.known.name.agent;
            this.id = mod_triger.uuidgen();
            this.msg_be_sent = {};
            this.msg_we_sent = {};

            if (i > 0) {
                this.path = arguments[0];
            }
            else if (i > 1) {
                this.js_file_path = arguments[1];
            }
            else if (i > 2) {
                this.win = arguments[2];
            }
            else if (i > 3) {
                this.status = arguments[3];
            }
            else if (i > 4) {
                this.is_the_js_file_insert = arguments[4];
            }
            else if (i > 5) {
                this.is_control_agent = arguments[5];
            }
            else if (i > 6) {
                throw 'It is too much arguments to create an Agent'
            }
        },

        AgentStatus: function(status_str) {
            if (status_str in mod_triger.agent_status_type) {
                this.status = status_str,
                this.status_id = mod_triger.uuidgen();
            }
            else
                throw status_str + ': unknown agent status type';
        },
        
        agent_status_type: {
            need_open: {
                to_create: function() {
                    
                }
            },
            agent_is_ready: {
                to_create: function() {
                    
                }
            },
            progress: {
                to_create: function() {
                    
                }
            },
            done: {
                to_create: function() {
                    
                }
            },
            busy: {
                to_create: function() {
                    
                }
            },
            no_response: {
                to_create: function() {
                    
                }
            },
            failed: {
                to_create: function() {
                    
                }
            },
            unknown_status: {
                to_create: function() {
                    
                }
            }
        },
        
        is_the_win_opened: function(win) {
            for (var i = 0;i < Agents.length;i++) {
                if (Agents[i].win === win) {
                    return true;
                }
            }
            return false;
        },

        
        get_agent_by_win: function(win) {
            var agent = null;
            
            for (var i = 0;i < Agents.length;i++) {
                if (Agents[i].win === win) {
                    agent = Agents[i];
                    break;
                }
            }

            if (agent === null) {
                throw 'No agent owns the msg ' + msg_id + ' from ' + w;
            }
            
            return agent;
        },

        
        get_agent_by_msg: function(msg) {
            return mod_triger.get_agent_by_win(msg.source);

        },

        get_agent_by_its_id: function(uuid) {
            var agent = null;
            for (var i = 0;i < Agents.length;i++) {
                if (Agents[i].id == uuid) {
                    agent = Agents[i];
                    break;
                }
            }

            if (agent === null) {
                throw 'No agent owns the msg ' + msg_id + ' from ' + w;
            }
            
            return agent;
        },

        get_agent_whose_has_msg_be_sent: function() {
            var agents = new Array();
            
            for (var i = 0;i < Agents.length;i++) {
                var agent = Agents[i];
                if (Object.keys(agent.msg_be_sent).length != 0)
                    agents.push(agent);
            }
            
            return agents;
        },

        get_agent_whose_has_no_msg_be_sent: function() {
            var agents = new Array();
            
            for (var i = 0;i < Agents.length;i++) {
                var agent = Agents[i];
                if (Object.keys(agent.msg_be_sent).length == 0)
                    agents.push(agent);
            }
            
            return agents;
        },

        get_agent_whose_has_msg_we_sent: function() {
            var agents = new Array();
            
            for (var i = 0;i < Agents.length;i++) {
                var agent = Agents[i];
                if (Object.keys(agent.msg_we_sent).length != 0)
                    agents.push(agent);
            }
            
            return agents;
        },

        get_agent_whose_has_no_msg_we_sent: function() {
            var agents = new Array();
            
            for (var i = 0;i < Agents.length;i++) {
                var agent = Agents[i];
                if (Object.keys(agent.msg_we_sent).length == 0)
                    agents.push(agent);
            }
            
            return agents;
        },

        /*
         *  Message()
         *  Message(type)
         *  Message(type, data)
         */
        Message: function(type, data) {
            if (type in mod_triger.msg_type) {
                this.name = mod_triger.known.name.msg;
                this.data_structure_id = mod_triger.known.uuid.msg_id,
                this.path = window.location.pathname;
                this.id = mod_triger.uuidgen();
                this.type = type;
                this.data = data;
            }
            else
                throw type + ': unknown message type'; 
        },


        msg_type: {
            'ack': {
                to_create: function(msg_received) {
                    var id_of_msg_received = msg_received.data.id;
                    return new mod_triger.Message(
                        'ack',
                        {
                            reply_to_msg: id_of_msg_received
                        }
                    );
                }
            },
            
            'nomal': {
                to_create: function(obj) {
                    return new mod_triger.Message(
                        'normal',
                        obj
                    );
                }
            },
            
            'urgent': {
                to_create: function(obj) {
                    return new mod_triger.Message(
                        'urgent',
                        obj
                    );
                }
            },
            
            'ping': {
                to_create: function(obj) {
                    return new mod_triger.Message(
                        'ping',
                        obj
                    );
                }    
            }
            
        },

        is_msg: function(msg) {
            if (msg.name == mod_triger.msg.name
                && msg.data_structure_id == mod_triger.known.uuid.msg_id
                && (msg.type in mod_triger.msg_type))
                return true;
            return false;
        },
        
        is_msg_for_win: function(msg, win) {
            if (mod_triger.is_msg(msg))
                if (msg.source === win)
                    return true;
            
            return false;
        },

        is_msg_for_agent: function(agent) {
            if (mod_triger.is_msg_for_win(agent.win))
                return true;
            
            return false;
        },
        
        
        ticket: {
            get: function() {
                var str_ticket = localStorage.getItem(mod_triger.uuid
                                                      .ticket_id);
                var ticket = JSON.parse(str_ticket);
            },
            
            do: function() {
                var ticket = mod_triger.ticket.get();
                                
                if ('target_path' in ticket 
                    && ticket.target_path != location.pathname) {
                    declare_self_is_ready();
                    return;
                }
                
                if (mod_triger.known.uuid.ticket_id in sessionStorage) {
                    var session_ticket_str =
                            sessionStorage.getItem(mod_triger.uuid
                                                   .ticket_id);
                    var session_ticket = JSON.parse(session_ticket_str);
                    if (session_ticket.status == 'assigned') {
                        declare_self_is_ready();
                        return;
                    }
                }
                
                ticket.status = "assigned";
                localStorage.setItem(mod_triger.known.uuid.ticket_id,
                                     JSON.stringify(ticket));
                sessionStorage.setItem(mod_triger.known.uuid.ticket_id,
                                       JSON.stringify(ticket));
                
                if ('js_file_path' in ticket) {
                    mod_triger.insert_js_file(ticket.js_file_path);
                    mod_triger.self.js_file_path = ticket.js_file_path;
                }
                else {
                    var default_js_file_path = mod_triger
                            .get_default_main_js_file_path();
                    
                    mod_triger.insert_js_file(default_js_file_path);
                    mod_triger.self.js_file_path = default_js_file_path;
                }
                
                mod_triger.self.is_the_js_file_insert = true;
                mod_triger.self.is_control_agent = true;
                
                declare_self_is_ready();
            }
        },

        
        get_default_js_file_dir: function() {
            if (location.protocol == 'file:') {
                return '';
            }
            else {
                var dir = location.origin.replace(/\//g, '')
                        .replace(':', '.');
                
                return '/'
                    + mod_triger.uuid.konwn.our_js_dir
                    +'/'
                    + dir
                    + '/';
            }
        },

        
        get_default_main_js_file_path: function() {
            var dir = mod_triger.get_default_js_file_dir();
            console.log("dir " + dir);
            if (location.protocol == 'file:') {
                return dir + location.pathname + '.js';
            }
            else {
                return dir + 'main.js';
            }
        },

        
        handler_to_store_received_msg: function(e) {
            if (e.origin != location.origin)
                return;

            try {
                var data = JSON.parse(e.data);
                if ('id' in data && data.data_structure_id == mod_triger.known.uuid.msg_id) {
                    if (data.type == 'insert_js') {
                        mod_triger
                            .insert_js_file(data.data.js_file_path);
                    }
                    else {
                        mod_triger.MsgStore.push({data: e.data,
                                                     source: e.source,
                                                     origin: e.origin});
                    }
                }
            }
            catch(e) {
                ;
            }
            finally {
                ;
            }
        },

        
        insert_js_file: function(path) {
            var script_tag = document.createElement("script");
            script_tag.src = path;
            script_tag.type = 'text/javascript';
            document.body.appendChild(script_tag);
        },

        
        declare_self_is_ready: function() {
            var msg = new mod_triger.Message('agent_is_ready', '');
            var msg_str = JSON.stringify(msg);
            var w = window.opener;
            if (w)
                w.postMessage(msg_str, w.location.origin);
            else
                mod_triger.self.status = msg;
        },
    };
    
    window.addEventListener('message',
                            mod_triger.handler_to_store_received_msg,
                            false);

    if (!(mod_triger.known.uuid.search_key in localStorage)) {
        localStorage.setItem(mod_triger.known.uuid.search_key,
                             location.origin);
        window.close();
    }
    
    if (mod_triger.known.uuid.ticket_id in localStorage) {
        if (mod_triger.self === null) {
            var self = new Agent(window.location.pathname, '');
            self.win = window;
            self.path = window.location.pathname;
            Agents.push(self);
            mod_triger.self = self;
        }
        
        mod_triger.ticket.do();
    } else {
        window.close();
    }
})();
