# agent.py
import json
import os
from google.adk.agents import LlmAgent
from google.adk.apps import App

# [START get_menu]
def get_menu() -> str:
  """
  Retrieves the menu from the menu.json file.

  Returns:
    str: A JSON string representing the list of menu items.
  """
  try:
    menu_path = os.path.join(os.path.dirname(__file__), "menu.json")
    with open(menu_path, "r") as f:
      menu_data = json.load(f)
      return json.dumps(menu_data)
  except Exception as e:
    return json.dumps({"[ERROR]" : f"Could not retrieve menu: {str(e)}"})
# [END get_menu]

# Barista agent
barista_agent = LlmAgent(
  name="barista_agent",
  model="gemini-2.5-flash",
  instruction="""
Your job is to recommend drinks and pastries to customers based on their preferences.

Rules you MUST follow:
1.  You must recommend items ONLY from the menu returned by get_menu().
2.  Do NOT recommend or suggest any item that is not present in the menu.
3.  If a user's preference is vague or unclear, ask exactly ONE friendly clarifying question to narrow down what they want (e.g., cold or hot, sweet or strong, coffee or pastry).
4.  Be warm and welcoming, but remain professional.
5.  Ground your recommendations in the actual tags, descriptions, and allergens listed in the menu (e.g., if a user is dairy-free, recommend ONLY items tagged 'dairy-free' or with no dairy allergens).
""",
  tools=[get_menu]
)

# Define app
app = App(
  name="coffee_barista_app",
  root_agent=barista_agent
)

