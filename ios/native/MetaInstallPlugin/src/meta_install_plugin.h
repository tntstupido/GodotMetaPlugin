#ifndef META_INSTALL_PLUGIN_H
#define META_INSTALL_PLUGIN_H

#include "core/object/class_db.h"
#include "core/object/object.h"
#include "core/string/ustring.h"

class MetaInstallPlugin : public Object {
	GDCLASS(MetaInstallPlugin, Object);

	bool initialized = false;

	static void _bind_methods();

public:
	Error initialize(const String &app_id, const String &client_token, const String &display_name, bool advertiser_id_collection);
	bool is_initialized() const;
	bool sync_advertiser_tracking_enabled();
	void flush();
	String get_sdk_version() const;

	MetaInstallPlugin() = default;
	~MetaInstallPlugin() = default;
};

#endif
