//  Copyright 2021 Abitofevrything and others.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import '../checks/checks.dart';
import '../commands.dart';
import '../commands/chat_command.dart';
import '../commands/interfaces.dart';
import '../commands/options.dart';
import '../context/base.dart';
import '../errors.dart';

mixin ParentMixin<T extends ICommandContext> implements ICommandRegisterable<T> {
  ICommandGroup<ICommandContext>? _parent;

  @override
  ICommandGroup<ICommandContext>? get parent => _parent;

  @override
  set parent(ICommandGroup<ICommandContext>? parent) {
    if (_parent != null) {
      throw CommandRegistrationError('Cannot register command "$name" again');
    }
    _parent = parent;
  }
}

mixin CheckMixin<T extends ICommandContext> on ICommandRegisterable<T> implements IChecked {
  final List<AbstractCheck> _checks = [];

  @override
  Iterable<AbstractCheck> get checks => [...?parent?.checks, ..._checks];

  @override
  void check(AbstractCheck check) {
    _checks.add(check);

    for (final preCallHook in check.preCallHooks) {
      onPreCall.listen(preCallHook);
    }

    for (final postCallHook in check.postCallHooks) {
      onPostCall.listen(postCallHook);
    }
  }
}

mixin OptionsMixin<T extends ICommandContext> on ICommandRegisterable<T> implements IOptions {
  @override
  CommandOptions get resolvedOptions {
    if (parent == null) {
      return options;
    }

    CommandOptions parentOptions = parent is ICommandRegisterable
        ? (parent as ICommandRegisterable).resolvedOptions
        : parent!.options;

    CommandType? parentType = parentOptions.type;
    if (parent is CommandsPlugin) {
      if ((parent as CommandsPlugin).prefix == null && parentType == CommandType.all) {
        parentType = CommandType.slashOnly;
      }
    }

    return CommandOptions(
      autoAcknowledgeInteractions:
          options.autoAcknowledgeInteractions ?? parentOptions.autoAcknowledgeInteractions,
      acceptBotCommands: options.acceptBotCommands ?? parentOptions.acceptBotCommands,
      acceptSelfCommands: options.acceptSelfCommands ?? parentOptions.acceptSelfCommands,
      hideOriginalResponse: options.hideOriginalResponse ?? parentOptions.hideOriginalResponse,
      type: options.type ?? parentType,
    );
  }
}
