from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_socketio import SocketIO
from flask_cors import CORS
from config import Config

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
socketio = SocketIO()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    socketio.init_app(app, cors_allowed_origins="*")
    CORS(app)

    # Import models to ensure they are registered with SQLAlchemy
    from app import models

    # Register blueprints
    from app.routes import auth, teams, projects, tasks
    app.register_blueprint(auth.bp, url_prefix='/api/auth')
    app.register_blueprint(teams.bp, url_prefix='/api/teams')
    app.register_blueprint(projects.bp, url_prefix='/api/projects')
    app.register_blueprint(tasks.bp, url_prefix='/api/tasks')
    
    from app.routes import files, notifications
    app.register_blueprint(files.bp, url_prefix='/api/files')
    app.register_blueprint(notifications.bp, url_prefix='/api/notifications')

    from app.routes import resources
    app.register_blueprint(resources.bp, url_prefix='/api/resources')

    from app.routes import timeline, learning
    app.register_blueprint(timeline.bp, url_prefix='/api/timeline')
    app.register_blueprint(learning.bp, url_prefix='/api/learning')

    from app.routes import dashboard
    app.register_blueprint(dashboard.bp, url_prefix='/api/dashboard')

    # Import socket events
    from app import events

    # Serve uploads
    from flask import send_from_directory
    import os
    
    @app.route('/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    # 健康检查接口：验证进程存活 + 数据库连通
    from sqlalchemy import text

    @app.route('/api/health')
    def health():
        try:
            db.session.execute(text('SELECT 1'))
            return jsonify({'status': 'ok'}), 200
        except Exception:
            return jsonify({'status': 'error', 'message': 'database unavailable'}), 503

    return app
