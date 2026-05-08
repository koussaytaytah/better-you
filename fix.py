import glob
import re
import os

lib_dir = 'lib'

methods = {
    'addPost': 'postRepositoryProvider',
    'deletePost': 'postRepositoryProvider',
    'likePost': 'postRepositoryProvider',
    'getComments': 'postRepositoryProvider',
    
    'updateUserProfile': 'userRepositoryProvider',
    'addXP': 'userRepositoryProvider',
    'warnUser': 'userRepositoryProvider',
    'banUser': 'userRepositoryProvider',
    'unbanUser': 'userRepositoryProvider',
    'reportUser': 'userRepositoryProvider',
    'checkAndAwardBadges': 'userRepositoryProvider',
    'searchUsers': 'userRepositoryProvider',
    'blockUser': 'userRepositoryProvider',
    'acceptFriendRequest': 'userRepositoryProvider',
    
    'resolveReport': 'socialRepositoryProvider',
    'sendMessage': 'socialRepositoryProvider',
    'markNotificationRead': 'socialRepositoryProvider',
    
    'updateDailyLog': 'dailyLogRepositoryProvider',
    
    'addQuest': 'questRepositoryProvider',
    'deleteQuest': 'questRepositoryProvider',
    
    'removeFriend': 'userRepositoryProvider',
    'addFriend': 'userRepositoryProvider'
}

for filepath in glob.glob(lib_dir + '/**/*.dart', recursive=True):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    if os.path.basename(filepath) == 'dashboard_screen.dart':
        if 'theme_provider.dart' not in content:
            content = content.replace(
                "import '../../../shared/providers/data_provider.dart';",
                "import '../../../shared/providers/data_provider.dart';\nimport '../../../shared/providers/theme_provider.dart';"
            )
            
    # For any remaining firestore references
    for method, provider in methods.items():
        pattern = r'\.read\(\s*firestoreServiceProvider\s*\)\s*\.\s*' + method
        content = re.sub(pattern, f'.read({provider}).{method}', content)
        
        pattern = r'\.watch\(\s*firestoreServiceProvider\s*\)\s*\.\s*' + method
        content = re.sub(pattern, f'.watch({provider}).{method}', content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed {filepath}')
