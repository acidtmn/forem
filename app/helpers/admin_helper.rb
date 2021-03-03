module AdminHelper
  # This is used in app/views/admin/shared/_navbar.html.erb to build the
  # side navbar in alphabetical order.
  # If you add an item before "config", please update the insert call in
  # admin_menu_items below.
  MENU_ITEMS = [
    { name: "articles",              controller: "articles" },
    { name: "broadcasts",            controller: "broadcasts" },
    { name: "badges",                controller: "badges" },
    { name: "badge_achievements",    controller: "badge_achievements" },
    { name: "chat_channels",         controller: "chat_channels" },
    { name: "comments",              controller: "comments" },
    { name: "config",                controller: "config" },
    { name: "display_ads",           controller: "display_ads" },
    { name: "events",                controller: "events" },
    { name: "html_variants",         controller: "html_variants" },
    { name: "listings",              controller: "listings" },
    { name: "moderator_actions",     controller: "moderator_actions" },
    { name: "mods",                  controller: "mods" },
    { name: "navigation_links",      controller: "navigation_links" },
    { name: "privileged_reactions",  controller: "privileged_reactions" },
    { name: "organizations",         controller: "organizations" },
    { name: "pages",                 controller: "pages" },
    { name: "permissions",           controller: "permissions" },
    { name: "podcasts",              controller: "podcasts" },
    { name: "reports",               controller: "reports" },
    { name: "response_templates",    controller: "response_templates" },
    { name: "sponsorships",          controller: "sponsorships" },
    { name: "tags",                  controller: "tags" },
    { name: "tools",                 controller: "tools" },
    { name: "users",                 controller: "users" },
    { name: "vault secrets",         controller: "secrets" },
    { name: "webhooks",              controller: "webhook_endpoints" },
    { name: "welcome",               controller: "welcome" },
  ].sort_by { |menu_item| menu_item[:name] }

  PROFILE_ADMIN = { name: "config: profile setup", controller: "profile_fields" }.freeze

  TECH_MENU_ITEMS = [
    { name: "data_update_scripts", controller: "data_update_scripts" },
  ].sort_by { |menu_item| menu_item[:name] }

  def admin_menu_items
    return MENU_ITEMS unless FeatureFlag.enabled?(:profile_admin)

    MENU_ITEMS.dup.insert(7, PROFILE_ADMIN)
  end

  # @ridhwana WIP on new admin navigation elements
  # The outer keys in NESTED_MENU_ITEMS need to correspond to the scope of the route
  # On second level navigation with more children, we reference the default tabs controller. i.e look at developer_tools
  NESTED_MENU_ITEMS = {
    overview: [{ name: "overview", controller: "" }],
    people: [{ name: "people", controller: "users" }],
    content_manager: [
      { name: "posts", controller: "articles" },
      { name: "comments", controller: "comments" },
      { name: "badges", controller: "badges", children: [
        { name: "badge library", controller: "badges" },
        { name: "badge achievements", controller: "badge_achievements" }
      ]}
    ],
    advanced: [
      { name: "broadcasts", controller: "broadcasts" },
      { name: "response_templates", controller: "response_templates" },
      { name: "sponsorships", controller: "sponsorships" },
      { name: "developer tools", controller: "tools", children: [
        { name: "tools", controller: "tools" },
        { name: "vault secrets", controller: "secrets" },
        { name: "webhooks", controller: "webhook_endpoints" }
      ]}
    ]
  }

  def get_nested_menu_items(group_name, child_nav_item)
    return NESTED_MENU_ITEMS[group_name].detect {
      |items| items[:name] == child_nav_item
    }
  end
end
