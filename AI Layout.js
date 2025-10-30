import React from "react";
import { Link, useLocation } from "react-router-dom";
import { createPageUrl } from "@/utils";
import { Calendar, Bookmark } from "lucide-react";

export default function Layout({ children, currentPageName }) {
  const location = useLocation();

  const tabs = [
    { name: "Feed", path: createPageUrl("Feed"), icon: Calendar },
    { name: "Saved", path: createPageUrl("Saved"), icon: Bookmark }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#003c6c] via-[#005a9c] to-[#f1a91b]">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/95 border-b border-gray-200 backdrop-blur-sm">
        <div className="max-w-2xl mx-auto">
          <div className="flex items-center justify-between px-4 py-3">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-[#003c6c] to-[#f1a91b] rounded-full flex items-center justify-center">
                <Calendar className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-bold text-gray-900">UCSC Events</h1>
            </div>
          </div>
          
          {/* Tab Navigation */}
          <div className="flex border-b border-gray-200">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = location.pathname === tab.path;
              return (
                <Link
                  key={tab.name}
                  to={tab.path}
                  className={`flex-1 flex items-center justify-center gap-2 py-3 text-sm font-medium transition-colors relative ${
                    isActive
                      ? "text-[#003c6c]"
                      : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  {tab.name}
                  {isActive && (
                    <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-[#003c6c] to-[#f1a91b] rounded-t-full" />
                  )}
                </Link>
              );
            })}
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-2xl mx-auto">
        {children}
      </main>
    </div>
  );
}
