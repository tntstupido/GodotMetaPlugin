#import "meta_install_plugin.h"
#import "meta_install_plugin_bootstrap.h"

#include "core/config/engine.h"

static MetaInstallPlugin *meta_install_plugin = nullptr;

void init_meta_install_plugin() {
	meta_install_plugin = memnew(MetaInstallPlugin);
	Engine::get_singleton()->add_singleton(Engine::Singleton("MetaInstallPlugin", meta_install_plugin));
}

void deinit_meta_install_plugin() {
	if (meta_install_plugin != nullptr) {
		memdelete(meta_install_plugin);
		meta_install_plugin = nullptr;
	}
}
